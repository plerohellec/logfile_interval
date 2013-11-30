module LogfileInterval
  class Logfile
    def initialize(filename)
      @filename = filename
    end

    def first_timestamp(parser)
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

    def each_parsed_line(parser)
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
  end
end
