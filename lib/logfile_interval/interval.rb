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

      @data = {}
      parser.columns.each do |name, options|
        next unless agg = options[:aggregator_class]
        if custom_options = options[:custom_options]
          @data[name] = agg.new(custom_options)
        else
          @data[name] = agg.new
        end
      end
    end

    def [](name)
      @data[name.to_sym].values
    end

    def each(&block)
      @data.each(&block)
    end

    def to_hash
      @data.inject({}) do |h, pair|
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
        next unless @data[name]
        group_by_value = record[options[:group_by]] if options[:group_by]
        @data[name].add(record[name], group_by_value)
      end
    end
  end
end
