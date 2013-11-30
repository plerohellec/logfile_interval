module LogfileInterval
  class IntervalBuilder
    attr_reader :logfile_set, :parser, :length

    def initialize(logfile_set, parser, length)
      @logfile_set  = logfile_set
      @parser       = parser
      @length       = length
    end

    def each_interval
      secs = (Time.now.to_i / length.to_i) * length.to_i
      rounded_end_time = Time.at(secs)
      current_interval = Interval.new(rounded_end_time, length, parser)

      logfile_set.each_parsed_line do |record|
        next if record.time > current_interval.end_time
        while record.time <= current_interval.start_time
          yield current_interval
          current_interval = Interval.new(current_interval.start_time, length, parser)
        end
        current_interval.add_record(record)
      end

      yield current_interval if current_interval.size>0
    end

    def last_interval
      each_interval do |interval|
        return interval
      end
    end
  end
end
