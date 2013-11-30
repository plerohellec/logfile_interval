module LogfileInterval
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

    def each_record_backward
      ordered_filenames.each do |filename|
        tfile = Logfile.new(@line_klass, filename)
        tfile.each_record_backward do |record|
          yield record
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

    def last_record
      each_record_backward do |record|
        return record
      end
    end
  end
end
