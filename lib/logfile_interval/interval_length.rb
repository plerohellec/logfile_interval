module LogfileInterval
  class IntervalLength
    MAX_PERIODS = { 5.minutes.to_i => 6.hours,
                    1.hour.to_i    => 1.day,
                    1.day.to_i     => 1.month,
                    1.month.to_i   => 1.years }
    LENGTHS = MAX_PERIODS.keys.sort

    attr_reader :length

    def initialize(l)
      raise ArgumentError unless LENGTHS.include?(l)
      @length = l
    end

    def lower
      pos = LENGTHS.index(@length)
      return nil if pos==0
      IntervalLength.new(LENGTHS[pos-1])
    end

    def higher
      pos = LENGTHS.index(@length)
      return nil if pos==LENGTHS.size-1
      IntervalLength.new(LENGTHS[pos+1])
    end

    def smallest?
      pos = LENGTHS.index(@length)
      pos == 0
    end

    def start_time(t)
      ts = (t.to_i / @length.to_i) * @length.to_i
      ts -= @length.to_i if t.to_i % @length.to_i == 0
      Time.at(ts)
    end

    def end_time(t)
      start_time(t) + @length
    end

    def to_i
      @length.to_i
    end
  end
end
