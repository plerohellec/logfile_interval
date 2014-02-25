module LogfileInterval
  module Aggregator
    class Delta < Base
      register_aggregator :delta, self

      def initialize
        @previous = Util::Counter.new
        super
      end

      def add(value, group_by = nil)
        if @previous.has_key?(key(group_by))
          @val.add(key(group_by), @previous[key(group_by)] - value)
          @size.increment(key(group_by))
        end
        @previous.set(key(group_by), value)
      end

      def val(k)
        average(k)
      end
    end
  end
end
