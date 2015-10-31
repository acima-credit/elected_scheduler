module Elected
  module Scheduler
    class Poller

      include Logging
      extend Forwardable

      attr_reader :key, :jobs

      def_delegators :@senado, :timeout

      def initialize(key, timeout = nil)
        @senado ||= Senado.new key, timeout
        @key    = key
        @jobs   = Concurrent::Hash.new
      end

      def add(job)
        @jobs[job.name] = job
        self
      end

      alias :<< :add

      def status
        @status ||= :stopped
      end

      def running?
        status == :running
      end

      def stopped?
        status == :stopped
      end

      def start
        return false unless stopped?
        raise 'No jobs to run!' if jobs.empty?

        debug "#{label} starting ..."
        @status = :starting
        start_polling_loop
        @status = :running
        debug "#{label} running poller!"
        @status
      end

      def stop
        return false unless running?

        debug "#{label} stopping poller ..."
        @status = :stopping
        stop_polling_loop
        senado.release
        @status = :stopped
        debug "#{label} stopped poller!"
        @status
      end

      def to_s
        %{#<#{self.class.name} key="#{key}" timeout="#{timeout}" jobs=#{jobs.size}>}
      end

      alias :inspect :to_s

      private

      attr_reader :senado

      def start_polling_loop
        debug 'starting process loop ...'
        @polling_loop_thread = Thread.new do
          poll_and_process_loop
        end
      end

      def poll_and_process_loop
        cnt = 0
        while running?
          cnt += 1
          debug "#{label(cnt)} calling poll_and_process_jobs while running?:#{running?} ..."
          poll_and_process_jobs
          sleep_until_next_tick
        end
      end

      def poll_and_process_jobs
        if senado.leader?
          debug "#{label} leader, processing jobs ..."
          start_time = Time.now
          jobs.values.each { |job| process_job job, start_time }
        else
          debug "#{label} not a leader, sleeping ..."
          sleep_for_slave
        end
      end

      def process_job(job, time)
        return false unless job.matches? time

        Concurrent::Future.execute { job.execute }
      end

      def stop_polling_loop
        if @polling_loop_thread
          @polling_loop_thread.join
          @polling_loop_thread.terminate
        end
      end

      def label(cnt = nil)
        "[#{key}:#{status}#{cnt ? ":#{cnt}" : ''}]"
      end

      def sleep_until_next_tick
        start = Time.now
        sleep 0.1 while Time.now.sec == start.sec
      end

      def sleep_for_slave(ratio = 0.25)
        deadline = Time.now + (timeout / 1_000.0) * ratio
        sleep 0.1 while Time.now < deadline
      end

    end

    extend self

    attr_writer :key, :timeout

    def key
      @key || 'elected_scheduler_poller'
    end

    def timeout
      @timeout || Elected.timeout
    end

    def poller
      @poller ||= Poller.new key, timeout
    end
  end
end