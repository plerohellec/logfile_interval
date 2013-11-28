module LogfileInterval
  class Logfile
    def initialize(line_klass, filename)
      @filename = filename
      @line_klass = line_klass
    end

    def first_timestamp
      return nil unless File.exist?(@filename)
      File.open(@filename) do |f|
        line = @line_klass.new(f.gets)
        line.parse
        line.timestamp
      end
    end

    def each_line_backward
      f = FileBackward.new(@filename)
      while(line = f.gets)
        yield line
      end
      f.close
    end

    def each_item_backward
      each_line_backward do |line|
        item = @line_klass.new(line)
        parsed = item.parse
        yield parsed if parsed
      end
    end
  end
end
