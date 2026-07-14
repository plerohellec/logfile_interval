module LogfileInterval
  module Aggregator
    class Sum < Base
      def add(value, group_by = nil)
        return if value.nil?
        @val.add(key(group_by), value)
      end
    end
  end
end
