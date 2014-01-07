module LogfileInterval
  module Aggregator
    class GroupAndCount < Base
      def each
        @val.each { |k, v| yield k, v }
      end

      def add(value, group_by)
        raise ArgumentError, 'group_by argument is mandatory for GroupAndCount#add' unless group_by
        @val.increment_subkey(value, key(group_by))
      end
    end
  end
end
