require File.join(File.expand_path('..', __FILE__), '/interval_builder/ascending')
require File.join(File.expand_path('..', __FILE__), '/interval_builder/descending')

module LogfileInterval
  class IntervalBuilder
    attr_reader :parsed_lines_enum, :parser_columns, :length

    def initialize(parsed_lines_enum, parser_columns, length, options = {})
      @parsed_lines_enum = parsed_lines_enum
      @parser_columns    = parser_columns
      @length            = length

      raise ArgumentError if options.include?(:boundary_offset) && options.include?(:offset_by_start_time)

      @boundary_offset      = options.fetch(:boundary_offset, 0)
      offset_by_start_time  = options.fetch(:offset_by_start_time, nil)
      if offset_by_start_time
        @boundary_offset = offset_by_start_time.to_i % length
      end

      case order
      when :asc  then self.extend Ascending
      else
        self.extend Descending
      end
    end

    def each_interval(&block)
      return enum_for(:each_interval) unless block_given?
      return if order == :empty

      current_interval = create_first_interval

      parsed_lines_enum.each do |record|
        next if out_of_order_record?(current_interval, record)
        current_interval = move_over_empty_intervals(current_interval, record) { |interval| yield interval }
        current_interval.add_record(record)
      end

      yield current_interval if current_interval.size > 0
    end

    def first_interval
      each_interval.first
    end

    def start_boundary_time(t)
      secs = ((t.to_i - @boundary_offset) / length.to_i) * length.to_i + @boundary_offset
      Time.at(secs)
    end

    def end_boundary_time(t)
      secs = ((t.to_i - @boundary_offset)/ length.to_i + 1) * length.to_i + @boundary_offset
      Time.at(secs)
    end

    private

    def order
      return @order if @order
      num_lines = 0
      previous = nil
      parsed_lines_enum.each do |pl|
        num_lines += 1
        if previous
          if pl.time > previous.time
            return @order = :asc
          elsif pl.time < previous.time
            return @order = :desc
          end
        end
        previous = pl
      end
      return @order = :empty if num_lines == 0
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
