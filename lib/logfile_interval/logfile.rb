module LogfileInterval
  class Logfile
    attr_reader :filename, :parser

    def initialize(filename, parser)
      @filename = filename
      @parser   = parser
    end

    def first_timestamp
      return nil unless File.exist?(@filename)
      File.open(@filename) do |f|
        line = parser.create_record(f.gets)
        line.time
      end
    end

    def each_line
      f = FileBackward.new(@filename)
      while(line = f.gets)
        yield line.chomp
      end
      f.close
    end

    def each_parsed_line
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
  end
end
