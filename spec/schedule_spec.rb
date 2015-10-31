require 'spec_helper'

module Elected
  module Scheduler
    describe Schedule, focus: true do
      let(:options) { {} }
      subject { described_class.new options }
      context 'default' do
        it 'can be instantiated' do
          expect(subject).to be_a described_class
        end
        it 'can present as a string' do
          expect(subject.to_cron_s).to eq '0 * * * * *'
          expect(subject.to_s).to eq '0 * * * * *'
          expect(subject.inspect).to eq '0 * * * * *'
        end
      end
      context 'values' do
        context 'seconds' do
          it('single  ') { expect_cron_s '3 * * * * *', seconds: 3 }
          it('multiple') { expect_cron_s '3,6,9 * * * * *', seconds: [3, 9, 6] }
          it('range   ') { expect_cron_s '3,4,5 * * * * *', seconds: 3..5 }
          it('mixed   ') { expect_cron_s '3,4,5,7,9,11 * * * * *', seconds: [3..5, 7, [9, 11]] }
        end
        context 'minutes' do
          it('single  ') { expect_cron_s '0 3 * * * *', minutes: 3 }
          it('multiple') { expect_cron_s '0 3,6,9 * * * *', minutes: [3, 9, 6] }
          it('range   ') { expect_cron_s '0 3,4,5 * * * *', minutes: 3..5 }
          it('mixed   ') { expect_cron_s '0 3,4,5,7,9,11 * * * *', minutes: [3..5, 7, [9, 11]] }
        end
        context 'hours' do
          it('single  ') { expect_cron_s '0 * 3 * * *', hours: 3 }
          it('multiple') { expect_cron_s '0 * 3,6,9 * * *', hours: [3, 9, 6] }
          it('range   ') { expect_cron_s '0 * 3,4,5 * * *', hours: 3..5 }
          it('mixed   ') { expect_cron_s '0 * 3,4,5,7,9,11 * * *', hours: [3..5, 7, [9, 11]] }
        end
        context 'days' do
          it('single  ') { expect_cron_s '0 * * 3 * *', days: 3 }
          it('multiple') { expect_cron_s '0 * * 3,6,9 * *', days: [3, 9, 6] }
          it('range   ') { expect_cron_s '0 * * 3,4,5 * *', days: 3..5 }
          it('mixed   ') { expect_cron_s '0 * * 3,4,5,7,9,11 * *', days: [3..5, 7, [9, 11]] }
        end
        context 'months' do
          it('single     ') { expect_cron_s '0 * * * 3 *', months: 3 }
          it('multiple   ') { expect_cron_s '0 * * * 3,6,9 *', months: [3, 9, 6] }
          it('range      ') { expect_cron_s '0 * * * 3,4,5 *', months: 3..5 }
          it('names long ') { expect_cron_s '0 * * * 1,2,3,4,5,6,7,8,9,10,11,12 *', months: %w{ January FEBRUARY march ApRiL may JuNe } + %i{ July august September OCTOBER NoVeMbEr dEcEmBeR } }
          it('names short') { expect_cron_s '0 * * * 1,2,3,4,5,6,7,8,9,10,11,12 *', months: %w{ Jan FEB march ApR may JuN } + %i{ Jul aug Sep OCT NoV dEc } }
          it('mixed      ') { expect_cron_s '0 * * * 1,2,3,4,5,7 *', months: [1..2, 3, [4, 'Jul'], :may] }
        end
        context 'dows' do
          it('single     ') { expect_cron_s '0 * * * * 3', dows: 3 }
          it('multiple   ') { expect_cron_s '0 * * * * 1,3,5', dows: [1, 3, 5] }
          it('range      ') { expect_cron_s '0 * * * * 3,4,5', dows: 3..5 }
          it('names long ') { expect_cron_s '0 * * * * 0,1,2,3,4,5,6', dows: %w{ Sunday monday TUESDAY WednesDay } + %i{ thursday Friday SATURDAY } }
          it('names short') { expect_cron_s '0 * * * * 0,1,2,3,4,5,6', dows: %w{ Sun mon TUE Wed } + %i{ thu Fri SAT } }
          it('mixed      ') { expect_cron_s '0 * * * * 0,1,2,3,4,5,6', dows: [0..1, 2, [:wed, 'thursday'], 'Fri', :SaT] }
        end
        context 'mixed' do
          it('mix #1') { expect_cron_s '0 15 8,9,10,11,12,13,14,15,16,17 * * 1,2,3,4,5', minutes: 15, hours: 8..17, dows: 1..5 }
          it('mix #2') { expect_cron_s '15,45 * 3,15 * * 0,6', seconds: [15, 45], hours: [3, 15], dows: %i{ sat sun } }
          it('mix #3') { expect_cron_s '0 * 8,12,15 1,15 * 1,2,3,4,5', days: [1, 15], hours: [8, 12, 15], dows: 1..5 }
        end
      end
      context 'matching' do
        it('all    ') { expect_schedule_match mk_time }
        it('seconds') { expect_schedule_match mk_time(sc: 45), seconds: [15, 45] }
        it('minutes') { expect_schedule_match mk_time(mi: 17), minutes: [17, 23] }
        it('hours  ') { expect_schedule_match mk_time(hr: 23), hours: 20..23 }
        it('days   ') { expect_schedule_match mk_time(dy: 15), days: [10..20] }
        it('dows   ') { expect_schedule_match mk_time(wd: 1), dows: :mon }
        it('mix #1 ') { expect_schedule_match mk_time(mi: 15, hr: 10, wd: 3), minutes: 15, hours: 8..17, dows: 1..5 }
        it('mix #2 ') { expect_schedule_match mk_time(sc: 45, hr: 15, wd: 6), seconds: [15, 45], hours: [3, 15], dows: %i{ sat sun } }
        it('mix #3 ') { expect_schedule_match mk_time(hr: 8, dy: 15, wd: 3), days: [1, 15], hours: [8, 12, 15], dows: 1..5 }
      end

    end
  end
end
