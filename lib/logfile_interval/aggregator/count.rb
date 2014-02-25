module LogfileInterval
  module Aggregator
    class Count < Base
      register_aggregator :count, self

      def each
        @val.each { |k, v| yield k, v }
      end

      def add(value, group_by_value = nil)
        if group_by_value
          @val.increment_subkey(value, key(group_by_value))
        else
          @val.increment(value)
        end
      end
    end
  end
end
