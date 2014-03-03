module LogfileInterval
  module Aggregator
    class NumLines < Base
      def initialize(options = {})
        super(options)
        @val = Util::SingleCounter.new
      end

      def add(value, group_by_value = nil)
        @val.increment(nil)
      end
    end
  end
end
