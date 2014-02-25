module LogfileInterval
  module Aggregator
    class Sum < Base
      register_aggregator :sum, self

      def add(value, group_by = nil)
        @val.add(key(group_by), value)
      end
    end
  end
end
