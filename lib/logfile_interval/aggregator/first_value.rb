module LogfileInterval
  module Aggregator
    class FirstValue < Base
      def initialize(options = {})
        super(options)
        @val = {}
      end

      def add(value, group_by = nil)
        @val[key(group_by)] = value
        @size.increment(key(group_by))
      end
    end
  end
end


