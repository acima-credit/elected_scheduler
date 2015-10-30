require 'spec_helper'

module Elected
  module Scheduler
    describe Poller do
      let(:key) { 'some_key' }
      let(:timeout) { 30_000 }
      subject { described_class.new key, timeout }
      it 'can be instantiated' do
        expect(subject).to be_a described_class
        expect(subject.key).to eq key
        expect(subject.timeout).to eq timeout
        expect(subject.jobs).to be_empty
      end
      context '#add' do
        it 'can add jobs sequentially' do
          subject << Job.new('a') << Job.new('b')
          expect(subject.jobs.keys).to eq %w{ a b }
        end
      end
      context 'flow', loglines: true do
        it 'starts, runs on time and stops' do
          expect(subject.status).to eq :stopped
          subject << Job.new('a') { $lines << 'a' }.at(seconds: [0, 2, 4, 6, 8])
          subject << Job.new('b') { $lines << 'b' }.at(seconds: [1, 3, 5, 7, 9])

          Timecop.travel mk_time(sc: 59)
          subject.start
          expect(subject.status).to eq :running

          $lines.wait_for_size 5
          subject.stop
          expect(subject.status).to eq :stopped

          expect($lines.all).to eq %w{ a b a b a }
        end
      end
      context '#to_s' do
        it('simple') { expect(subject.to_s).to eq %{#<Elected::Scheduler::Poller key="#{key}" timeout="#{timeout}" jobs=0>} }
      end
    end
  end
end