module LogfileInterval
  module Aggregator
    class CountOverThreshold < Base
      def initialize(options)
        super
        @threshold = options.fetch(:threshold)
      end

      def add(value, group_by = nil)
        @val.add(key(group_by), 1) if value > @threshold
      end
    end
  end

  module ParsedLine
    class CustomTimingLog < Base
      # Line format:
      # timestamp, ip, controller#action, total_time, bytes, rss

      set_line_parser :logfile_line

      set_regex /^(\d+),\s*([\d\.]+),\s*(\w+#\w+),\s*(\d+),\s*(\d+),\s*([\d\.]+)$/

      add_column :name => :timestamp,    :pos => 1, :aggregator => :timestamp
      add_column :name => :ip,           :pos => 2, :aggregator => :count
      add_column :name => :num_slow,     :pos => 4, :aggregator => :count_over_threshold,    :conversion => :integer,
                 :custom_options => { :threshold => 100 }

      def time
        Time.at(self.timestamp.to_i)
      end
    end
  end
end
