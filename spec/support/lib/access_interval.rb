module LogfileInterval
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

    def self.each_interval(filenames, interval_length, options={}, &block)
      logfile_set = LogfileSet.new(AccessLine, filenames)
      Interval.each_interval(AccessInterval, logfile_set, interval_length, options, &block)
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
  end
end
