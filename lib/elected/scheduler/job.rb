module Elected
  module Scheduler
    class Job

      include Logging

      attr_reader :name, :callback, :schedules

      def initialize(name, &blk)
        @name      = name.to_s
        @callback  = blk if block_given?
        @schedules = Set.new
      end

      def run(&blk)
        raise 'must pass a block' unless block_given?
        @callback = blk
        self
      end

      def at(options = {})
        schedules.add Schedule.new(options)
        self
      end

      def matches?(time)
        schedules.any? { |s| s.matches? time }
      end

      def execute
        callback.call
        true
      rescue Exception => e
        error "Exception: #{e.class.name} : #{e.message}\n  #{e.backtrace[0, 10].join("\n  ")}"
        return false
      end

      def to_s
        %{#<#{self.class.name} name="#{name}" schedules=#{schedules.map { |x| x.to_s }.inspect}>}
      end

      alias :inspect :to_s

    end
  end
end