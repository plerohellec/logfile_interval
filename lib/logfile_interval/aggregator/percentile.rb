module LogfileInterval
  module Aggregator
    class Percentile < Base
      def initialize(options = {})
        super(options)
        @val = {}
      end

      def add(value, group_by = nil)
        return if value.nil?
        k = key(group_by)
        @val[k] ||= []
        @val[k] << value
        @size.increment(k)
      end

      def compute_percentile(p, group = nil)
        sorted = values_for(group)
        return 0 if sorted.nil? || sorted.empty?

        n = sorted.length
        rank = (p / 100.0) * (n - 1)
        lower = rank.floor
        upper = rank.ceil

        if lower == upper
          sorted[lower]
        else
          sorted[lower] + (sorted[upper] - sorted[lower]) * (rank - lower)
        end
      end

      private

      def val(k)
        compute_percentile(50, k == :all ? nil : k)
      end

      def values_for(group)
        arr = group ? @val[group] : @val.values.flatten
        arr.sort if arr
      end
    end
  end
end
