module LogfileInterval
  module Interval
    attr_reader   :start_time, :end_time, :length
    attr_accessor :size

    class OutOfRange < StandardError; end
    class BadLength  < StandardError; end

    def initialize(end_time, length)
      raise ArgumentError, 'end_time must be round' unless (end_time.to_i % length.to_i == 0)
      @end_time   = end_time
      @start_time = end_time - length
      @length     = length
      @size = 0
    end

    def self.each_interval_backward(interval_klass, logfile_set, interval_length, options={})
      secs = (Time.now.to_i / interval_length.to_i) * interval_length.to_i
      rounded_end_time = Time.at(secs)
      current_interval = interval_klass.new(rounded_end_time, interval_length, options)

      logfile_set.each_record_backward do |record|
        next if record.timestamp > current_interval.end_time
        while record.timestamp <= current_interval.start_time
          yield current_interval
          current_interval = interval_klass.new(current_interval.start_time, interval_length, options)
        end
        current_interval.add(record)
      end

      yield current_interval if current_interval.size>0
    end

    def self.last_interval(interval_klass, logfile_set, interval_length, options={})
      each_interval_backward(interval_klass, logfile_set, interval_length, options) do |interval|
        return interval
      end
    end

    def add(record)
      raise OutOfRange, 'too recent' if record.timestamp>@end_time
      raise OutOfRange, 'too old'    if record.timestamp<=@start_time
      @size += 1
    end

    def interval_length
      @interval_length ||= IntervalLength.new(self.length)
    end

    def ==(i)
      self.end_time == i.end_time && self.length == i.length && self.size == i.size
    end
  end
end
