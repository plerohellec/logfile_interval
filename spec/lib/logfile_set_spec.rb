require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/access_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe LogfileSet do
    before :each do
      @logfiles = ["#{data_dir}/access.log.2", "#{data_dir}/access.log.1"]
      @set = LogfileSet.new(LineParser::AccessLog, @logfiles)
    end

    it 'ordered_filenames should return the most recent file first' do
      @set.ordered_filenames.should == @logfiles.reverse
    end

    it 'each_line should enumerate each line in file backwards' do
      lines = []
      @set.each_line do |line|
        lines << line
      end

      lines.first.should == '66.249.67.176 - - [23/Jun/2013:17:00:01 -0800] "GET /package/core/raring/universe/proposed/openldap HTTP/1.1" 200 185 "-" "Google"'
      lines.last.should == '12.24.48.96 - - [23/Jun/2013:16:49:00 -0800] "GET /package/core/raring/universe/proposed/bash HTTP/1.1" 200 4555 "-" "Bing)"'
    end

    it 'each_parsed_line should enumerate each line backwards' do
      records = []
      @set.each_parsed_line do |record|
        records << record
      end

      records.first.time.should == Time.new(2013, 06, 23, 17, 00, 01, '-08:00')
      records.first.code.should == '200'
      records.last.time.should  == Time.new(2013, 06, 23, 16, 49, 00, '-08:00')
      records.last.code.should == '200'
    end
  end
end
