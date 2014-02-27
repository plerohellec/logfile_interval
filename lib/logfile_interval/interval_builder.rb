module LogfileInterval
  class IntervalBuilder
    attr_reader :parsed_lines_enum, :parser_columns, :length

    def initialize(parsed_lines_enum, parser_columns, length)
      @parsed_lines_enum = parsed_lines_enum
      @parser_columns    = parser_columns
      @length            = length
    end

    def each_interval
      return enum_for(:each_interval) unless block_given?

      secs = (Time.now.to_i / length.to_i) * length.to_i
      rounded_end_time = Time.at(secs)
      current_interval = Interval.new(rounded_end_time, length, parser_columns)

      parsed_lines_enum.each do |record|
        next if record.time > current_interval.end_time
        while record.time <= current_interval.start_time
          yield current_interval
          current_interval = Interval.new(current_interval.start_time, length, parser_columns)
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
