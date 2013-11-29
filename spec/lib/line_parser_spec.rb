require 'spec_helper'

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  module LineParser

    class AccessLog < Base
      # Example line:
      # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

      set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/

      add_column :name => 'ip',        :pos => 1, :agg_function => :group
      add_column :name => 'timestamp', :pos => 2, :agg_function => :timestamp
      add_column :name => 'length',    :pos => 5, :agg_function => :average,   :conversion => :integer

      def time
        Time.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z')
      end
    end

    describe AccessLog do
      it 'parses an access.log line' do
        line = '74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"'
        parsed_line = AccessLog.new(line)
        parsed_line.ip.should == '74.75.19.145'
        parsed_line.length.should == 7855
        parsed_line.timestamp.should == '31/Mar/2013:06:54:12 -0700'
        parsed_line.time.should == Time.strptime('31/Mar/2013:06:54:12 -0700', '%d/%b/%Y:%H:%M:%S %z')
      end

      it 'should raise an error id line is malformed' do
        line = 'abcdef'
        lambda { AccessLog.new(line) }.should raise_error InvalidLine
      end

      it 'must fail unless a regex is set'
      it 'must fail unless a column is configured'
    end
  end
end


