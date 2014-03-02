module LogfileInterval
  module Aggregator
    class NumLines < Base
      def add(value, group_by_value = nil)
        if group_by_value
          @val.increment_subkey(:all, key(group_by_value))
        else
          @val.increment(:all)
        end
      end
    end
  end
end
