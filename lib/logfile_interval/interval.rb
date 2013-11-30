module LogfileInterval
  class Interval
    attr_reader   :start_time, :end_time, :length, :parser
    attr_reader   :size

    class OutOfRange < StandardError; end
    class BadLength  < StandardError; end
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
        case options[:agg_function]
        when :sum       then @data[name] = 0
        when :average   then @data[name] = 0
        when :group     then @data[name] = Counter.new
        end
      end
    end

    def [](name)
      case parser.columns[name][:agg_function]
      when :sum       then @data[name]
      when :average   then size>0 ? @data[name].to_f / size.to_f : 0.0
      when :group     then @data[name]
      end
    end

    def add_record(record)
      return unless record.valid?
      raise ParserMismatch unless record.class == parser
      raise OutOfRange, 'too recent' if record.time>@end_time
      raise OutOfRange, 'too old'    if record.time<=@start_time

      @size += 1

      parser.columns.each do |name, options|
        case options[:agg_function]
        when :sum       then @data[name] += record[name]
        when :average   then @data[name] += record[name]
        when :group     then @data[name].increment(record[name])
        end
      end
    end

    def ==(i)
      self.end_time == i.end_time && self.length == i.length && self.size == i.size
    end
  end
end
