module LogfileInterval
  module Util
    class Counter < Hash
      def increment(key)
        if self.has_key?(key)
          self[key] += 1
        else
          self[key] = 1
        end
      end

      def increment_subkey(key, subkey)
        if self.has_key?(key) && !self[key].is_a?(Counter)
          raise "Value for #{key} is not a Counter"
        end

        unless self.has_key?(key)
          self[key] = Counter.new
        end
        self[key].increment(subkey)
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

      def value(k)
        self[k]
      end

      def values
        self.inject({}) { |h, v| h[v[0]] = v[1]; h }
      end
    end
  end
end
