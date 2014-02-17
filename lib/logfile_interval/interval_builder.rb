module LogfileInterval
  class IntervalBuilder
    attr_reader :parsed_line_enum, :parser, :length

    def initialize(parsed_line_enum, parser, length)
      @parsed_line_enum = parsed_line_enum
      @parser           = parser
      @length           = length
    end

    def each_interval
      return enum_for(:each_interval) unless block_given?

      secs = (Time.now.to_i / length.to_i) * length.to_i
      rounded_end_time = Time.at(secs)
      current_interval = Interval.new(rounded_end_time, length, parser)

      parsed_line_enum.each do |record|
        next if record.time > current_interval.end_time
        while record.time <= current_interval.start_time
          yield current_interval
          current_interval = Interval.new(current_interval.start_time, length, parser)
        end
        current_interval.add_record(record)
      end

      yield current_interval if current_interval.size>0
    end

    def last_interval
      each_interval do |interval|
        return interval
      end
    end
  end
end
