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
        next unless agg = options[:aggregator]
        @data[name] = agg.new
      end
    end

    def [](name)
      @data[name].value
    end

    def add_record(record)
      return unless record.valid?
      raise ParserMismatch unless record.class == parser
      raise OutOfRange, 'too recent' if record.time>@end_time
      raise OutOfRange, 'too old'    if record.time<=@start_time

      @size += 1

      parser.columns.each do |name, options|
        next unless @data[name]
        @data[name].add(record[name])
      end
    end
  end
end
