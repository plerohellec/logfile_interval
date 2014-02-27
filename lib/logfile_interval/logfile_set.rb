module LogfileInterval
  class LogfileSet
    attr_reader :parser

    ORDER_VALID_VALUES = [ :asc, :desc ]

    def initialize(filenames, parser, order = :desc)
      @parser    = parser
      @filenames = filenames
      @order    = order

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
        file = Logfile.new(filename, parser)
        h[filename] = file.first_timestamp
        h
      end
    end
  end
end
