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
      it 'has stats' do
        expect(subject.stats.to_s).to eq '#<Elected::Stats no_match=0 processed_job=0 sleep_slave=0>'
      end
      context '#add' do
        it 'can add jobs sequentially' do
          subject << Job.new('a') << Job.new('b')
          expect(subject.jobs.keys).to eq %w{ a b }
        end
      end
      context 'flow', loglines: true, focus: true do
        let(:other) { described_class.new key, timeout }
        it 'cannot start on empty jobs' do
          expect { subject.start }.to raise_exception RuntimeError, 'No jobs to run!'
        end
        it 'starts, runs on time and stops' do
          expect(subject.status).to eq :stopped
          expect(other.status).to eq :stopped

          subject << Job.new('even') { $lines << 'even' }.at(seconds: 30.times.map { |x| x * 2 })
          subject << Job.new('odd') { $lines << 'odd' }.at(seconds: 30.times.map { |x| x * 2 + 1 })

          other << Job.new('all') { $lines << 'all' }.at(seconds: :all)

          wait_until { subject.leader? }
          expect(other).to_not be_leader

          subject.start
          other.start

          expect(subject.status).to eq :running
          expect(other.status).to eq :running

          $lines.wait_for_size 6, 10

          subject.stop
          expect(subject.status).to eq :stopped

          expect(other.status).to eq :running
          expect(other).to be_leader

          $lines.wait_for_size 9, 10

          other.stop
          expect(other.status).to eq :stopped

          expect($lines.sorted).to eq %w{ all all all even even even odd odd odd }
          expect(subject.stats.count(:processed_job)).to eq 6
          expect(other.stats.count(:processed_job)).to eq 3
        end
      end
      context '#to_s' do
        it('simple') { expect(subject.to_s).to eq %{#<Elected::Scheduler::Poller key="#{key}" timeout="#{timeout}" jobs=0>} }
      end
    end
  end
  describe Scheduler do
    it 'has a default poller' do
      expect(described_class.poller).to be_a Scheduler::Poller
    end
  end
end