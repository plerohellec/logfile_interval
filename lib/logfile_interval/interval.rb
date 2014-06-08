module LogfileInterval
  class Interval
    attr_reader   :start_time, :end_time, :length, :parser
    attr_reader   :size

    class OutOfRange < StandardError; end

    def initialize(end_time, length, parser_columns)
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
      h = @aggregators.to_hash
      h[:start_time] = self.start_time
      h[:end_time] = self.end_time
      h
    end

    def add_record(record)
      raise OutOfRange, 'too recent' if record.time>@end_time
      raise OutOfRange, 'too old'    if record.time<=@start_time

      @size += 1
      @aggregators.add(record)
    end
  end
end
