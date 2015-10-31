require 'rspec/expectations'
require 'rspec/core/shared_context'
require 'timecop'

ENV['REDIS_URL'] ||= 'redis://localhost:6379/0'

DEFAULT_KEY     = 'test_elected_scheduler'
DEFAULT_TIMEOUT = 5_000

FOCUSED     = ENV['FOCUS'] == 'true'
PERFORMANCE = ENV['PERFORMANCE'] == 'true'
DEBUG       = ENV['DEBUG'] == 'true'

module TestingHelpers

  extend RSpec::Core::SharedContext

  class LogLines

    include Elected::Logging

    attr_reader :all

    def initialize
      @all = Concurrent::Array.new
    end

    def sorted
      all.sort { |a, b| a <=> b }
    end

    def clear
      @all.clear
    end

    def add(msg)
      debug 'add | %s' % msg
      @all << msg
    end

    def wait_for_size(nr, timeout = 15)
      start_time  = Time.now
      last_time   = start_time + timeout
      cnt, status = 0, nil
      loop do
        cnt    += 1
        status = if @all.size >= nr
                   :enough
                 elsif Time.now >= last_time
                   :timed_out
                 else
                   :keep
                 end
        break unless status == :keep
        debug 'cnt : %i | status : %s | size: %i/%i | left : %.2fs' % [cnt, status, @all.size, nr, last_time - Time.now] if cnt % 10 == 0
        sleep 0.05
      end
      took = last_time - Time.now
      debug 'cnt : %i | status : %s | size: %i/%i | took : %.2fs (%.2fr/s)' % [cnt, status, @all.size, nr, took, cnt / took.to_f]
      Time.now - start_time
    end

    alias :<< :add

    def has_line?(str)
      @all.any? { |x| x.include? str }
    end

    def size
      @all.size
    end

    def to_s
      %{#<#{self.class.name} size=#{@all.size} all=#{@all.inspect}>}
    end

    alias :inspect :to_s

  end

  class TestLogger

    attr_reader :lines

    def initialize
      @lines = Array.new
    end

    def debug(string)
      lines << string
    end

    def info(string)
      lines << string
    end

    def warn(string)
      lines << string
    end

    def error(string)
      lines << string
    end

    def has_line?(str)
      lines.any? { |x| x.include? str }
    end

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

  def mk_wday(nr, start = Date.today)
    raise "Invalid wday nr [#{nr}]" if nr < 0 || nr > 6
    return start if start.wday == nr
    mk_wday nr, start - 1
  end

  def mk_time(options = {})
    options = { sc: 0 }.update options
    now     = Time.now
    day     = mk_wday options.fetch(:wd, now.wday)

    Time.new options.fetch(:yr, day.year),
             options.fetch(:mo, day.month),
             options.fetch(:dy, day.day),
             options.fetch(:hr, now.hour),
             options.fetch(:mi, now.min),
             options.fetch(:sc, now.sec)
  end

  def expect_cron_s(exp_str, options = {})
    expect(described_class.new(options).to_cron_s).to eq exp_str
  end

  def expect_schedule_match(time, options = {})
    sch = Elected::Scheduler::Schedule.new options
    expect(sch.matches?(time)).to eq(true),
                                  "expected time [#{time.to_s}|#{time.wday}]\n" +
                                    "     to match [#{sch}]"
  end

  def expect_logger_line(msg)
    expect($logger.has_line?(msg)).to eq(true),
                                      "expected #{$logger.lines.inspect}\n" +
                                        "to have  [#{msg}]"

  end

  def expect_no_logger_lines
    expect($logger.lines.size).to eq 0
  end

  def expect_line(msg)
    expect($lines.has_line?(msg)).to eq(true),
                                     "expected #{$logger.lines.inspect}\n" +
                                       "to have  [#{msg}]"

  end

  def expect_no_lines
    expect($lines.size).to eq 0
  end
end