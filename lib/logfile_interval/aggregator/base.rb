module LogfileInterval
  module Aggregator
    class Base
      include Enumerable

      def initialize(options = {})
        @val = Util::Counter.new
        @size = Util::Counter.new
      end

      def value(group = nil)
        val(key(group))
      end

      def values
        if single_value?
          value
        else
          self.inject({}) { |h, v| h[v[0]] = v[1]; h }
        end
      end

      def add(value, group_by = nil)
        raise NotImplementedError
      end

      private
      def key(group_by = nil)
        group_by ? group_by : :all
      end

      def single_value?
        return true if @val.empty?
        @val.keys.count == 1 && @val.keys.first == :all
      end

      def each
        @val.each_key do |k|
          yield k, val(k)
        end
      end

      def val(k)
        @val[k]
      end

      def average(k)
        @size[k] > 0 ? @val[k].to_f / @size[k].to_f : 0
      end
    end
  end
end