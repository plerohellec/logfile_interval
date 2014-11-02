module LogfileInterval
  class LogfileSet
    attr_reader :parser

    ORDER_VALID_VALUES = [ :asc, :desc ]

    def initialize(filenames, parser, order = :desc, &file_time_finder_block)
      @parser    = parser
      @filenames = filenames
      @order    = order
      @file_time_finder_block = file_time_finder_block if block_given?

      reject_empty_files!
      reject_files_with_no_valid_line!

      raise ArgumentError, "invalid order value: #{@order}" unless ORDER_VALID_VALUES.include?(@order.to_sym)
    end

    def ordered_filenames
      time_for_files = time_for_files(existing_filenames)
      order_filenames_asc = time_for_files.to_a.sort_by { |arr| arr[1] }.map { |arr| arr[0] }
      case @order
      when :desc
        order_filenames_asc.reverse
      when :asc
        order_filenames_asc
      end
    end

    def each_parsed_line(&block)
      return enum_for(__method__) unless block_given?
      each_by_method(__method__, &block)
    end
    alias_method :each, :each_parsed_line

    def each_line(&block)
      return enum_for(__method__) unless block_given?
      each_by_method(__method__, &block)
    end

    def first_parsed_line
      each_parsed_line.first
    end
    alias_method :first, :first_parsed_line

    private

    def existing_filenames
      @existing_filenames ||= @filenames.select { |f| File.exist?(f) }
    end

    def each_by_method(method, &block)
      ordered_filenames.each do |filename|
        tfile = Logfile.new(filename, parser, @order)
        tfile.send(method) do |line|
          yield line
        end
      end
    end

    def time_for_files(filenames)
      filenames.inject({}) do |h, filename|
        if @file_time_finder_block
          t = @file_time_finder_block.call(filename)
        else
          file = Logfile.new(filename, parser)
          t = file.first_timestamp
        end
        h[filename] = t
        h
      end
    end

    def reject_empty_files!
      @filenames.reject do |fname|
        !File.size?(fname)
      end
    end

    def reject_files_with_no_valid_line!
      @filenames.reject! do |fname|
        file = Logfile.new(fname, parser)
        !file.first_parsed_line
      end
    end
  end
end
