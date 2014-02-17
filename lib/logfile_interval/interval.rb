module LogfileInterval
  class Interval
    attr_reader   :start_time, :end_time, :length, :parser
    attr_reader   :size

    class OutOfRange < StandardError; end
    class ParserMismatch < StandardError; end

    def initialize(end_time, length, parser)
      raise ArgumentError, 'end_time must be round' unless (end_time.to_i % length.to_i == 0)
      @end_time   = end_time
      @start_time = end_time - length
      @length     = length
      @parser     = parser
      @size = 0

      @aggregators = {}
      parser.columns.each do |name, options|
        next unless klass = options[:aggregator_class]
        if custom_options = options[:custom_options]
          @aggregators[name] = klass.new(custom_options)
        else
          @aggregators[name] = klass.new
        end
      end
    end

    def [](name)
      raise ArgumentError, "#{name} field does not exist" unless @aggregators.has_key?(name)
      @aggregators[name.to_sym].values
    end

    def each(&block)
      @aggregators.each(&block)
    end

    def to_hash
      @aggregators.inject({}) do |h, pair|
        k = pair[0]
        v = pair[1]
        h[k] = v.values
        h
      end
    end

    def add_record(record)
      return unless record.valid?
      raise ParserMismatch unless record.class == parser
      raise OutOfRange, 'too recent' if record.time>@end_time
      raise OutOfRange, 'too old'    if record.time<=@start_time

      @size += 1

      parser.columns.each do |name, options|
        next unless @aggregators[name]
        group_by_value = record[options[:group_by]] if options[:group_by]
        @aggregators[name].add(record[name], group_by_value)
      end
    end
  end
end
