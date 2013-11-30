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
end
