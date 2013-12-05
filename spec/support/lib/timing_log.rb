module LogfileInterval
  module LineParser
    class TimingLog < Base
      # Line format:
      # timestamp, controller#action, total_time, bytes

      set_regex /^(\d+),\s*(\w+#\w+),\s*(\d+),\s*(\d+),\s*([\d\.]+)$/

      add_column :name => :timestamp,    :pos => 1, :agg_function => :timestamp
      add_column :name => :action,       :pos => 2, :agg_function => :group
      add_column :name => :total_time,   :pos => 3, :agg_function => :average,   :conversion => :integer
      add_column :name => :num_bytes,    :pos => 4, :agg_function => :sum,       :conversion => :integer
      add_column :name => :rss,          :pos => 5, :agg_function => :delta,     :conversion => :float

      def time
        Time.at(self.timestamp.to_i)
      end
    end

    class TimingLogWithGrouping < Base
      # Line format:
      # timestamp, controller#action, total_time, bytes

      set_regex /^(\d+),\s*(\w+#\w+),\s*(\d+),\s*(\d+),\s*([\d\.]+)$/

      add_column :name => :timestamp,    :pos => 1, :agg_function => :timestamp
      add_column :name => :action,       :pos => 2, :agg_function => :group
      add_column :name => :total_time,   :pos => 3, :agg_function => :average,   :conversion => :integer, :group_by => :action
      add_column :name => :num_bytes,    :pos => 4, :agg_function => :sum,       :conversion => :integer, :group_by => :action
      add_column :name => :rss,          :pos => 5, :agg_function => :delta,     :conversion => :float,   :group_by => :action

      def time
        Time.at(self.timestamp.to_i)
      end
    end
  end
end
