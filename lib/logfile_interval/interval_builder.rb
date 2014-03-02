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

      current_interval = case order
      when :asc  then first_interval_ascending(&block)
      when :desc then first_interval_descending(&block)
      else raise 'unknown enumerator order'
      end

      parsed_lines_enum.each do |record|
        next if out_of_order_record?(current_interval, record)
        current_interval = move_over_empty_intervals(current_interval, record) { |interval| yield interval }
        current_interval.add_record(record)
      end

      yield current_interval if current_interval.size > 0
    end

    def last_interval
      each_interval do |interval|
        return interval
      end
    end

    private

    def first_interval_ascending
      first_record = parsed_lines_enum.first
      interval_end_time = upper_boundary_time(first_record.time)
      current_interval = Interval.new(interval_end_time, length, parser_columns)
    end

    def first_interval_descending
      interval_end_time = lower_boundary_time(Time.now)
      current_interval = Interval.new(interval_end_time, length, parser_columns)
    end

    def lower_boundary_time(t)
      secs = (t.to_i / length.to_i) * length.to_i
      Time.at(secs)
    end

    def upper_boundary_time(t)
      secs = (t.to_i / length.to_i + 1) * length.to_i
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
      while past_current_interval?(current_interval, record)
        yield current_interval
        current_interval = Interval.new(next_interval_end_time(current_interval), length, parser_columns)
      end
      current_interval
    end

    def past_current_interval?(current_interval, record)
      case order
      when :asc  then record.time  > current_interval.end_time
      when :desc then record.time <= current_interval.start_time
      end
    end

    def out_of_order_record?(current_interval, record)
      case order
      when :asc  then record.time <= current_interval.start_time
      when :desc then record.time  > current_interval.end_time
      end
    end

    def next_interval_end_time(current_interval)
      case order
      when :asc  then current_interval.end_time + length
      when :desc then current_interval.end_time - length
      end
    end
  end
end
