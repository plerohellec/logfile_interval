module LogfileInterval
  module Aggregator
    class Average < Base
      def add(value, group_by = nil)
        return if value.nil?
        @val.add(key(group_by), value)
        @size.increment(key(group_by))
      end

      def val(k)
        average(k)
      end
    end
  end
end
