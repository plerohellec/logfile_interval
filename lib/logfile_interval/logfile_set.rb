module LogfileInterval
  class LogfileSet
    attr_reader :parser

    def initialize(filenames, parser)
      @parser    = parser
      @filenames = filenames
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
      time_for_file.to_a.sort_by { |arr| arr[1] }.map { |arr| arr[0] }.reverse
    end

    def each_parsed_line
      return enum_for(:each_parsed_line) unless block_given?

      ordered_filenames.each do |filename|
        tfile = Logfile.new(filename, parser)
        tfile.each_parsed_line do |record|
          yield record
        end
      end
    end

    def each_line
      return enum_for(:each_line) unless block_given?

      ordered_filenames.each do |filename|
        tfile = Logfile.new(filename, parser)
        tfile.each_line do |line|
          yield line
        end
      end
    end

    def last_record
      each_parsed_line do |record|
        return record
      end
    end
  end
end
