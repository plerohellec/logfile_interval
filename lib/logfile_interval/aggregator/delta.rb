module LogfileInterval
  module Aggregator
    class Delta < Base
      def initialize(options = {})
        @previous = {}
        super
        unless options.has_key?(:group_by)
          @val = Util::SingleCounter.new
        end
      end

      def add(value, group_by_value = nil)
        if @previous.has_key?(key(group_by_value))
          @val.add(key(group_by_value), value - @previous[key(group_by_value)])
          @size.increment(key(group_by_value))
        end
        @previous[key(group_by_value)] = value
      end

      def val(k)
        average(k)
      end
    end
  end
end
