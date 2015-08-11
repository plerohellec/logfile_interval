module LogfileInterval
  module Aggregator
    class Appender < Base
      def initialize(options = {})
        super(options)
        @val = {}
      end

      def add(value, group_by = nil)
        @val[key(group_by)] ||= Set.new
        @val[key(group_by)].add(value)
        @size.increment(key(group_by))
      end
    end
  end
end

