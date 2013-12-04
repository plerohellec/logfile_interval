module LogfileInterval
  module LineParser
    class Counter < Hash
      def increment(key)
        if self.has_key?(key)
          self[key] += 1
        else
          self[key] = 1
        end
      end

      def add(key, num)
        if self.has_key?(key)
          self[key] += num
        else
          self[key] = num
        end
      end

      def [](key)
        self.fetch(key, 0)
      end

      def merge(c)
        c.keys.each do |k|
          self.add c[k]
        end
      end
    end
  end
end
