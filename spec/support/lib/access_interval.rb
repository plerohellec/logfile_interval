module LogfileInterval
  class Counter < Hash
    def increment(val)
      if self.has_key?(val)
        self[val] += 1
      else
        self[val] = 1
      end
    end

    def add(val, num)
      if self.has_key?(val)
        self[val] += num
      else
        self[val] = num
      end
    end

    def merge(c)
      c.keys.each do |k|
        self.add c[k]
      end
    end
  end

  class AccessInterval
    include Interval

    attr_reader :ips, :codes, :exts, :uas, :referers

    def initialize(end_time, length, options={})
      super(end_time, length)
      @ips      = Counter.new
      @codes    = Counter.new
      @exts     = Counter.new
      @uas      = Counter.new
      @referers = Counter.new
    end

    def self.each_interval_backward(filenames, interval_length, options={}, &block)
      logfile_set = LogfileSet.new(AccessLine, filenames)
      Interval.each_interval_backward(AccessInterval, logfile_set, interval_length, options, &block)
    end

    def add(access)
      raise ArgumentError unless access.is_a?(AccessLine)
      super(access)

      ips.increment(access.ip)
      codes.increment(access.code)
      exts.increment(access.ext)
      uas.increment(access.ua)
      referers.increment(access.referer)
    end

    def add_sub_interval(interval)
      raise ArgumentError unless timing.is_a?(AccessInterval)
      super(interval)

      ips.merge(interval.ip)
      codes.merge(interval.code)
      exts.merge(interval.ext)
      uas.merge(interval.ua)
      referers.merge(interval.referer)
    end
  end
end
