module Elected
  module Scheduler
    class Schedule

      include Logging

      FIELDS = { seconds: :sec, minutes: :min, hours: :hour, days: :day, months: :month, dows: :wday }.freeze

      ABBR_DAYNAMES = %w{ sun mon tue wed thu fri sat }
      DAYNAMES      = %w{ sunday monday tuesday wednesday thursday friday saturday }

      MONTHNAMES      = %w{ january february march april may june july august september october november december }
      ABBR_MONTHNAMES = %w{ jan feb mar apr may jun jul aug sep oct nov dec }

      def self.defaults
        @defaults ||= { seconds: [0] }
      end

      def initialize(options = {})
        @options = options
        setup *FIELDS.keys
      end

      def matches?(time)
        FIELDS.all? { |field, meth| match? field, time.send(meth) }
      end

      def to_cron_s
        FIELDS.keys.map do |field|
          value = get field
          case value
            when :all
              '*'
            when Range, Array
              value.map { |x| x.to_s }.join(',')
          end
        end.join(' ')
      end

      alias :to_s :to_cron_s
      alias :inspect :to_cron_s

      private

      def get(field)
        instance_variable_get "@#{field}"
      end

      alias :[] :get

      def set(field, value)
        instance_variable_set "@#{field}", convert(field, value)
      end

      alias :[]= :set

      def default(field)
        self.class.defaults[field] || :all
      end

      def setup(*fields)
        fields.each do |field|
          set field, @options.fetch(field, default(field))
        end
      end

      def convert(field, value)
        case field
          when :seconds, :minutes, :hours, :days
            convert_numbers field, value
          when :months
            convert_months value
          when :dows
            convert_dows value
        end
      end

      def match?(field, exp_value)
        value = get field
        return true if value === :all
        value.include? exp_value
      end

      def convert_numbers(field, value)
        max = { seconds: 60, minutes: 60, hours: 23, days: 31 }[field]
        case value
          when :all
            value
          when Integer
            simplify_enum [value], 0, max
          when Array, Range
            simplify_enum value, 0, max
          else
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for #{field}"
        end
      end

      def simplify_enum(ary, min, max)
        ary.to_a.flatten.map do |x|
          x.is_a?(Range) ? simplify_enum(x.to_a, min, max) : x.to_i
        end.flatten.uniq.sort.
          select { |x| x >= min && x <= max }
      end

      def convert_months(value)
        case value
          when :all
            value
          when Integer, Symbol, String
            convert_months [value]
          when Array, Range
            ary = value.map { |x| convert_month x }
            simplify_enum ary, 1, 12
          else
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for month"
        end
      end

      def convert_month(value)
        case value
          when Integer
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for month" if value < 1 || value > 12
            value
          when Array, Range
            ary = value.map { |x| convert_month x }
            simplify_enum ary, 1, 12
          when String, Symbol
            idx = [ABBR_MONTHNAMES, MONTHNAMES].map { |ary| ary.index value.to_s.downcase }.compact.first
            raise "[#{idx}] Unknown value (#{value.class.name}) #{value.inspect}] for month" if idx.nil? || idx < 0 || idx > 11
            idx + 1
          else
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for month"
        end
      end

      def convert_dows(value)
        case value
          when :all
            value
          when Integer, Symbol, String
            convert_dows [value]
          when Array, Range
            ary = value.map { |x| convert_dow x }
            simplify_enum ary, 0, 6
          else
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for dow"
        end
      end

      def convert_dow(value)
        case value
          when Integer
            value
          when Array, Range
            ary = value.map { |x| convert_dow x }
            simplify_enum ary, 0, 6
          when String, Symbol
            idx = [ABBR_DAYNAMES, DAYNAMES].map { |ary| ary.index value.to_s.downcase }.compact.first
            raise "[#{idx}] Unknown value (#{value.class.name}) #{value.inspect}] for dow" if idx.nil? || idx < 0 || idx > 6
            idx
          else
            raise "Unknown value (#{value.class.name}) #{value.inspect}] for dow"
        end
      end

    end
  end
end
