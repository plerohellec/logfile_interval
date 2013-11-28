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

  class LogfileSet
    def initialize(line_klass, filenames)
      @filenames = filenames
      @line_klass = line_klass
    end

    def existing_filenames
      @existing_filenames ||= @filenames.select { |f| File.exist?(f) }
    end

    def ordered_filenames
      time_for_file = existing_filenames.inject({}) do |h, filename|
        file = Logfile.new(@line_klass, filename)
        h[filename] = file.first_timestamp
        h
      end
      time_for_file.to_a.sort_by { |arr| arr[1] }.map { |arr| arr[0] }.reverse
    end

    def each_item_backward
      ordered_filenames.each do |filename|
        tfile = Logfile.new(@line_klass, filename)
        tfile.each_item_backward do |item|
          yield item
        end
      end
    end

    def each_line_backward
      ordered_filenames.each do |filename|
        tfile = Logfile.new(@line_klass, filename)
        tfile.each_line_backward do |line|
          yield line
        end
      end
    end

    def last_item
      each_item_backward do |item|
        return item
      end
    end
  end
end
