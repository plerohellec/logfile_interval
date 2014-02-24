module LogfileInterval
  class Interval
    attr_reader   :start_time, :end_time, :length, :parser
    attr_reader   :size

    class OutOfRange < StandardError; end
    class ParserMismatch < StandardError; end

    def initialize(end_time, length, parser_columns)
      raise ArgumentError, 'end_time must be round' unless (end_time.to_i % length.to_i == 0)
      @end_time   = end_time
      @start_time = end_time - length
      @length     = length
      @parser     = parser
      @size = 0

      @aggregators = AggregatorSet.new(parser_columns)
    end

    def [](name)
      @aggregators[name]
    end

    def to_hash
      @aggregators.to_hash
    end

    def add_record(record)
      raise OutOfRange, 'too recent' if record.time>@end_time
      raise OutOfRange, 'too old'    if record.time<=@start_time

      @size += 1
      @aggregators.add(record)
    end
  end
end
