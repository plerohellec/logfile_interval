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

    def existing_filenames
      @existing_filenames ||= @filenames.select { |f| File.exist?(f) }
    end

    def ordered_filenames
      time_for_file = existing_filenames.inject({}) do |h, filename|
        file = Logfile.new(filename, parser)
        h[filename] = file.first_timestamp
        h
      end
      case @order
      when :desc
        time_for_file.to_a.sort_by { |arr| arr[1] }.map { |arr| arr[0] }.reverse
      when :asc
        time_for_file.to_a.sort_by { |arr| arr[1] }.map { |arr| arr[0] }
      end
    end

    def each_parsed_line
      return enum_for(:each_parsed_line) unless block_given?

      ordered_filenames.each do |filename|
        tfile = Logfile.new(filename, parser, @order)
        tfile.each_parsed_line do |record|
          yield record
        end
      end
    end
    alias_method :each, :each_parsed_line

    def each_line
      return enum_for(:each_line) unless block_given?

      ordered_filenames.each do |filename|
        tfile = Logfile.new(filename, parser, @order)
        tfile.each_line do |line|
          yield line
        end
      end
    end
  end
end
