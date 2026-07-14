module LogfileInterval
  module Aggregator
    class FirstValue < Base
      def initialize(options = {})
        super(options)
        @val = {}
      end

      def add(value, group_by = nil)
        return if value.nil?
        if !@val[key(group_by)]
          @val[key(group_by)] = value
        end
        @size.increment(key(group_by))
      end
    end
  end
end


