module LogfileInterval
  module Aggregator
    class Sum < Base
      def initialize(options = {})
        super(options)
        unless options.has_key?(:group_by)
          @val = Util::SingleCounter.new
        end
      end

      def add(value, group_by = nil)
        @val.add(key(group_by), value)
      end
    end
  end
end
