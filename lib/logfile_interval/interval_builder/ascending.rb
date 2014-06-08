module LogfileInterval
  class IntervalBuilder
    module Ascending
      def create_first_interval
        first_record = parsed_lines_enum.first
        interval_end_time = end_boundary_time(first_record.time)
        Interval.new(interval_end_time, length, parser_columns)
      end

      def past_current_interval?(current_interval, record)
        record.time  > current_interval.end_time
      end

      def out_of_order_record?(current_interval, record)
        record.time <= current_interval.start_time
      end

      def next_interval_end_time(current_interval)
        current_interval.end_time + length
      end
    end
  end
end
