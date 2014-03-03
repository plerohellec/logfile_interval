module LogfileInterval
  class Logfile
    attr_reader :filename, :parser

    ORDER_VALID_VALUES = [ :asc, :desc ]

    def initialize(filename, parser, order = :desc)
      @filename = filename
      @parser   = parser
      @order    = order

      raise ArgumentError, "invalid order value: #{@order}" unless ORDER_VALID_VALUES.include?(@order.to_sym)
    end

    def exist?
      filename && File.exist?(@filename)
    end

    def first_timestamp
      return unless exist?
      File.open(@filename) do |f|
        while line = f.gets
          if record = parser.create_record(line)
            return record.time
          end
        end
      end
    end

    def each_line
      return unless exist?
      return enum_for(:each_line) unless block_given?

      case @order
      when :asc
        each_line_ascending { |l| yield l }
      when :desc
        each_line_descending { |l| yield l }
      end
    end

    def each_parsed_line
      return enum_for(:each_parsed_line) unless block_given?
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
    alias_method :each, :each_parsed_line

    def first_parsed_line
      each_parsed_line.first
    end
    alias_method :first, :first_parsed_line

    private
    def each_line_descending
      f = Util::FileBackward.new(@filename)
      while(line = f.gets)
        yield line.chomp
      end
      f.close
    end

    def each_line_ascending
      File.open(@filename) do |f|
        f.each_line do |line|
          yield line.chomp
        end
      end
    end
  end
end
