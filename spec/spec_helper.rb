unless Object.const_defined? :SPEC_HELPER_LOADED

  $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
  require 'elected/scheduler'
  require 'timecop'

  ENV['REDIS_URL'] ||= 'redis://localhost:6379/0'

  DEFAULT_KEY     = 'test_elected_scheduler'
  DEFAULT_TIMEOUT = 5_000

  RSpec.configure do |c|

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

    c.after(:each) do
      Elected.senado.release
    end

    def wait_until(time)
      sleep 0.1 until Time.now >= time
    end

    def set_start_time
      @start_time = Time.now
    end

    def wait_for_timeout(fraction)
      wait_until @start_time + (@timeout / 1_000.0) * fraction
    end

  end

  SPEC_HELPER_LOADED = true
end