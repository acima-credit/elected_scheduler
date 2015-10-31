module Elected
  module Scheduler
    class Schedule

      include Logging

      FIELDS = { seconds: :sec, minutes: :min, hours: :hour, days: :day, months: :month, dows: :wday }.freeze

      ABBR_DAYNAMES = %w{ sun mon tue wed thu fri sat }.freeze
      DAYNAMES      = %w{ sunday monday tuesday wednesday thursday friday saturday }.freeze

      MONTHNAMES      = %w{ '' january february march april may june july august september october november december }.freeze
      ABBR_MONTHNAMES = %w{ '' jan feb mar apr may jun jul aug sep oct nov dec }.freeze

      MIN_NUMBERS = { seconds: 0, minutes: 0, hours: 0, days: 1, months: 1, dows: 0 }.freeze
      MAX_NUMBERS = { seconds: 59, minutes: 59, hours: 23, days: 31, months: 12, dows: 6 }.freeze

      def self.defaults
        @defaults ||= { seconds: [0] }
      end

      def initialize(options = {})
        @options = options
        setup *(FIELDS.keys)
      end

      def matches?(time)
        FIELDS.all? { |field, meth| match? field, time.send(meth) }
      end

      def to_cron_s
        FIELDS.keys.map { |field| get_cron_s(field) }.join(' ')
      end

      alias :to_s :to_cron_s
      alias :inspect :to_cron_s

      private

      def get(field)
        instance_variable_get "@#{field}"
      end

      alias :[] :get

      def get_cron_s(field)
        value = get(field)
        value === :all ? '*' : value.map { |x| x.to_s }.join(',')
      end

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
        return value if value === :all

        ary = simplify_enum Array(value).flatten
        case field
          when :seconds, :minutes, :hours, :days
            convert_numbers field, ary
          when :months
            convert_numbers :months, ary, :convert_month_name
          when :dows
            convert_numbers :dows, ary, :convert_dow_name
        end
      end

      def simplify_enum(ary)
        ary.map { |x| x.is_a?(Range) ? x.to_a : x }.flatten
      end

      def convert_numbers(field, ary, converter_name = nil)
        ary.map do |x|
          converter_name ? send(converter_name, x) : x
        end.select do |x|
          x.is_a?(Integer) && x >= MIN_NUMBERS[field] && x <= MAX_NUMBERS[field]
        end.uniq.sort
      end

      def convert_month_name(value)
        return value unless value.is_a?(String) || value.is_a?(Symbol)

        [ABBR_MONTHNAMES, MONTHNAMES].map { |ary| ary.index value.to_s.downcase }.compact.first
      end

      def convert_dow_name(value)
        return value unless value.is_a?(String) || value.is_a?(Symbol)

        [ABBR_DAYNAMES, DAYNAMES].map { |ary| ary.index value.to_s.downcase }.compact.first
      end

      def match?(field, exp_value)
        value = get field
        return true if value === :all

        value.include? exp_value
      end

    end
  end
end
