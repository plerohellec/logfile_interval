require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/access_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  module LineParser

    describe AccessLog do
      before :each do
        @line = '74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"'
      end

      it 'parses an access.log line' do
        parsed_line = AccessLog.new(@line)
        parsed_line.ip.should == '74.75.19.145'
        parsed_line.length.should == 7855
        parsed_line.timestamp.should == '31/Mar/2013:06:54:12 -0700'
        parsed_line.time.should == Time.strptime('31/Mar/2013:06:54:12 -0700', '%d/%b/%Y:%H:%M:%S %z')
      end

      it 'returns an invalid record if line is malformed' do
        line = 'abcdef'
        record = 'unset'
        lambda { record = AccessLog.new(line) }.should_not raise_error
        record.valid?.should be_false
      end

      context :create_record do

        it 'instanciates a new AccessLog object' do
          record = AccessLog.create_record(@line)
          record.should be_a(AccessLog)
          record.ip.should == '74.75.19.145'
        end

        it 'returns nil if line is malformed' do
          line = 'abcdef'
          record = AccessLog.create_record(line)
          record.should be_nil
        end
      end
    end

    describe 'Broken parsers' do
      class NoRegexLog < Base
        add_column :name => 'ip',        :pos => 1, :agg_function => :group
      end

      class NoColumnLog < Base
        set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/
      end

      before :each do
        @line = '74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"'
      end

      it 'must fail unless a regex is set' do
        lambda { NoRegexLog.new(@line) }.should raise_error ConfigurationError
      end

      it 'must fail unless a column is configured'do
        lambda { NoColumnLog.new(@line) }.should raise_error ConfigurationError
      end
    end
  end
end


