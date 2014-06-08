module LogfileInterval
  class IntervalBuilder
    module Descending
      def create_first_interval
        interval_end_time = start_boundary_time(Time.now)
        Interval.new(interval_end_time, length, parser_columns)
      end

      def past_current_interval?(current_interval, record)
        record.time <= current_interval.start_time
      end

      def out_of_order_record?(current_interval, record)
        record.time  > current_interval.end_time
      end

      def next_interval_end_time(current_interval)
        current_interval.end_time - length
      end
    end
  end
end
