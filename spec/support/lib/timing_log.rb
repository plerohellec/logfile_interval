module LogfileInterval
  module ParsedLine
    class TimingLog < Base
      # Line format:
      # timestamp, ip, controller#action, total_time, bytes, rss

      set_regex /^(\d+),\s*([\d\.]+),\s*(\w+#\w+),\s*(\d+),\s*(\d+),\s*([\d\.]+)$/

      add_column :name => :timestamp,    :pos => 1, :aggregator => :timestamp
      add_column :name => :ip,           :pos => 2, :aggregator => :count
      add_column :name => :action,       :pos => 3, :aggregator => :count
      add_column :name => :total_time,   :pos => 4, :aggregator => :average,   :conversion => :integer
      add_column :name => :num_bytes,    :pos => 5, :aggregator => :sum,       :conversion => :integer
      add_column :name => :rss,          :pos => 6, :aggregator => :delta,     :conversion => :float

      def time
        Time.at(self.timestamp.to_i)
      end
    end

    class TimingLogWithGrouping < Base
      # Line format:
      # timestamp, controller#action, total_time, bytes

      set_regex /^(\d+),\s*([\d\.]+),\s*(\w+#\w+),\s*(\d+),\s*(\d+),\s*([\d\.]+)$/

      add_column :name => :timestamp,    :pos => 1, :aggregator => :timestamp
      add_column :name => :ip_by_action, :pos => 2, :aggregator => :count,     :group_by => :action
      add_column :name => :action,       :pos => 3, :aggregator => :count
      add_column :name => :total_time,   :pos => 4, :aggregator => :average,   :group_by => :action, :conversion => :integer
      add_column :name => :num_bytes,    :pos => 5, :aggregator => :sum,       :group_by => :action, :conversion => :integer
      add_column :name => :rss,          :pos => 6, :aggregator => :delta,     :group_by => :action, :conversion => :float

      def time
        Time.at(self.timestamp.to_i)
      end
    end
  end
end
