require 'spec_helper'

module Elected
  describe Scheduler do
    it 'has a version number' do
      expect(Elected::Scheduler::VERSION).not_to be nil
    end
  end
end
