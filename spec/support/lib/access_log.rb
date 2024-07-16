module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  module ParsedLine

    class AccessLog < Base
      # Example line:
      # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"
      set_line_parser :logfile_line

      set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/

      add_column :name => 'ip',           :pos => 1, :aggregator => :count,                              :group_by => 'ip'
      add_column :name => 'timestamp',    :pos => 2, :aggregator => :timestamp
      add_column :name => 'code',         :pos => 4, :aggregator => :count,                              :group_by => 'ip'
      add_column :name => 'length',       :pos => 5, :aggregator => :average,   :conversion => :integer
      add_column :name => 'length_by_ip', :pos => 5, :aggregator => :average,   :conversion => :integer, :group_by => 'ip'

      skip :pos => 7, :regex => /Spinn3r/

      def time
        Time.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z')
      end
    end
  end
end
