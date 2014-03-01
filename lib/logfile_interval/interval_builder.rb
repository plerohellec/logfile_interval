module LogfileInterval
  class IntervalBuilder
    attr_reader :parsed_lines_enum, :parser_columns, :length

    def initialize(parsed_lines_enum, parser_columns, length)
      @parsed_lines_enum = parsed_lines_enum
      @parser_columns    = parser_columns
      @length            = length
    end

    def each_interval(&block)
      return enum_for(:each_interval) unless block_given?

      case order
      when :asc  then each_interval_ascending(&block)
      when :desc then each_interval_descending(&block)
      else raise 'unknown enumerator order'
      end
    end

    def last_interval
      each_interval do |interval|
        return interval
      end
    end

    private

    def each_interval_ascending
      secs = (Time.now.to_i / length.to_i) * length.to_i
      rounded_end_time = Time.at(secs)
      current_interval = Interval.new(rounded_end_time, length, parser_columns)


      parsed_lines_enum.each do |record|
        unless current_interval
          rounded_end_time = interval_end_time(record.time)
          current_interval = Interval.new(rounded_end_time, length, parser_columns)
        end


      end
    end

    def each_interval_descending
      rounded_end_time = interval_end_time(Time.now)
      current_interval = Interval.new(rounded_end_time, length, parser_columns)

      parsed_lines_enum.each do |record|
        next if record.time > current_interval.end_time
        current_interval = move_over_empty_intervals(current_interval, record) { |interval| yield interval }
        current_interval.add_record(record)
      end

      yield current_interval if current_interval.size>0
    end

    def interval_end_time(t)
      secs = (t.to_i / length.to_i) * length.to_i
      Time.at(secs)
    end

    def order
      return @order if @order
      previous = nil
      parsed_lines_enum.each do |pl|
        if previous
          if pl.time > previous.time
            return @order = :asc
          elsif pl.time < previous.time
            return @order = :desc
          end
        end
        previous = pl
      end
      return @order = :unknown
    end

    def move_over_empty_intervals(current_interval, record)
      while record.time <= current_interval.start_time
        yield current_interval
        current_interval = Interval.new(current_interval.start_time, length, parser_columns)
      end
      current_interval
    end
  end
end
