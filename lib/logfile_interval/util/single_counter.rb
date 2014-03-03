module LogfileInterval
  module Util
    class SingleCounter
      def initialize
        @num = 0
      end

      def increment(k)
        @num += 1
      end

      def add(k, v)
        @num += v
      end

      def [](k)
        @num
      end

      def value(k)
        @num
      end

      def values
        value(nil)
      end

      def empty?
        @num == 0
      end
    end
  end
end
