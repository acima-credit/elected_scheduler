require 'spec_helper'

module Elected
  module Scheduler
    describe Job do
      let(:job_name) { 'some_job' }
      subject { described_class.new job_name }
      context 'can be instantiated' do
        it 'with just a name' do
          expect(subject).to be_a described_class
          expect(subject.name).to eq job_name
          expect(subject.callback).to be_nil
          expect(subject.schedules).to be_empty
        end
        it 'with a name and callback' do
          subject = described_class.new(job_name) { puts 'hi!' }
          expect(subject.name).to eq job_name
          expect(subject.callback).to be_a Proc
          expect(subject.schedules).to be_empty
        end
        it 'with a name, callback and schedules' do
          subject = described_class.new(job_name) { puts 'hi!' }.at(seconds: 5).at(minutes: 10)
          expect(subject.name).to eq job_name
          expect(subject.callback).to be_a Proc
          expect(subject.schedules.map { |x| x.to_s }).to eq(['5 * * * * *', '0 10 * * * *'])
        end
        it 'with just name and then add callback and schedules separately' do
          subject = described_class.new(job_name)
          subject.run { puts 'hi!' }
          subject.at seconds: 5
          subject.at minutes: 10
          expect(subject.name).to eq job_name
          expect(subject.callback).to be_a Proc
          expect(subject.schedules.map { |x| x.to_s }).to eq(['5 * * * * *', '0 10 * * * *'])
        end
      end
      context '#matches?' do
        let(:time) { mk_time sc: 10 }
        let(:result) { subject.matches? time }
        it 'returns true on a single match' do
          subject.at(seconds: [1, 3]).at(seconds: [7, 10]).at(seconds: [15, 18])
          expect(result).to eq true
        end
        it 'returns true on a multiple match' do
          subject.at(seconds: [1, 3]).at(seconds: [7, 10]).at(seconds: [10, 12])
          expect(result).to eq true
        end
        it 'returns false on no match' do
          subject.at(seconds: [1, 3]).at(seconds: [6, 9]).at(seconds: [12, 15])
          expect(result).to eq false
        end
      end
      context '#execute' do
        context 'runs the callback', logging: true do
          let(:result) { subject.execute }
          it 'and returns true on success' do
            subject.run { 1 }
            expect(result).to eq true
            expect_no_logger_lines
          end
          it 'returns false on exception' do
            subject.run { raise 'Some weird error' }
            expect(result).to eq false
            expect_logger_line 'Exception: RuntimeError : Some weird error'
          end
        end
      end
      context '#to_s' do
        it('simple') { expect(subject.to_s).to eq %{#<Elected::Scheduler::Job name="#{job_name}" schedules=[]>} }
      end
    end
  end
end