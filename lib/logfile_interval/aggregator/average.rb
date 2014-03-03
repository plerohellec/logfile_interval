module LogfileInterval
  module Aggregator
    class Average < Base
      def initialize(options = {})
        super(options)
        unless options.has_key?(:group_by)
          @val = Util::SingleCounter.new
        end
      end

      def add(value, group_by = nil)
        @val.add(key(group_by), value)
        @size.increment(key(group_by))
      end

      def val(k)
        average(k)
      end
    end
  end
end
