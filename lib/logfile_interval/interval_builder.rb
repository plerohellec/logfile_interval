require File.join(File.expand_path('..', __FILE__), '/interval_builder/ascending')
require File.join(File.expand_path('..', __FILE__), '/interval_builder/descending')

module LogfileInterval
  class IntervalBuilder
    attr_reader :parsed_lines_enum, :parser_columns, :length

    def initialize(parsed_lines_enum, parser_columns, length)
      @parsed_lines_enum = parsed_lines_enum
      @parser_columns    = parser_columns
      @length            = length

      case order
      when :asc  then self.extend Ascending
      when :desc then self.extend Descending
      else raise ArgumentError, "Can't determine parsed_lines_enum sort order"
      end
    end

    def each_interval(&block)
      return enum_for(:each_interval) unless block_given?

      current_interval = create_first_interval

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
  end
end
