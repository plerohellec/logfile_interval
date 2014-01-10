module LogfileInterval
  class Logfile
    attr_reader :filename, :parser

    def initialize(filename, parser)
      @filename = filename
      @parser   = parser
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

      f = Util::FileBackward.new(@filename)
      while(line = f.gets)
        yield line.chomp
      end
      f.close
    end

    def each_parsed_line
      return enum_for(:each_parsed_line) unless block_given?
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
  end
end
