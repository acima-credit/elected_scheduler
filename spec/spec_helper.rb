unless Object.const_defined? :SPEC_HELPER_LOADED

  $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
  require 'elected/scheduler'
  require 'timecop'

  require_relative '../spec/support'

  RSpec.configure do |c|

    c.include TestingHelpers

    c.filter_run focus: true if FOCUSED
    c.filter_run_excluding performance: true unless PERFORMANCE
    Elected.logger.level = Logger::DEBUG if DEBUG

    # Setup defaults for testing
    c.before(:each) do
      Elected.key        = DEFAULT_KEY
      Elected.timeout    = DEFAULT_TIMEOUT
      Elected.redis_urls = ENV['REDIS_URL']
    end

    # Freeze to current time on specs tagged :freeze_current_time
    c.before(:each, freeze_current_time: true) do
      Timecop.freeze Time.now
    end

    # Always return to real time
    c.after(:each) do
      Timecop.return
    end

    # Get thread-safe line array
    c.around(:example, loglines: true) do |example|
      $lines = TestingHelpers::LogLines.new
      example.run
      $lines = nil
    end

    # Get an inspectable logger
    c.around(:example, logging: true) do |example|
      old_logger     = Elected.logger
      $logger        = TestingHelpers::TestLogger.new
      Elected.logger = $logger
      example.run
      Elected.logger = old_logger
      $logger        = nil
    end

  end

  SPEC_HELPER_LOADED = true
end