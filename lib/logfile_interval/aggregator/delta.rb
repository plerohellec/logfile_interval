module LogfileInterval
  module Aggregator
    class Delta < Base
      def initialize(options = {})
        @previous = Util::Counter.new
        super
      end

      def add(value, group_by_value = nil)
        if @previous.has_key?(key(group_by_value))
          @val.add(key(group_by_value), value - @previous[key(group_by_value)])
          @size.increment(key(group_by_value))
        end
        @previous.set(key(group_by_value), value)
      end

      def val(k)
        average(k)
      end
    end
  end
end
