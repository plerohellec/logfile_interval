require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/access_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe Logfile do
    before :each do
      @alf = Logfile.new("#{data_dir}/access.log")
    end

    it 'first_timestamp returns time of first line in file' do
      #01/Jan/2012:00:57:47 -0800
      @alf.first_timestamp(LineParser::AccessLog).should == Time.new(2012, 01, 01, 00, 57, 47, '-08:00')
    end

    it 'each_line should enumerate each line in file backwards' do
      lines = []
      @alf.each_line do |line|
        lines << line
      end

      lines.first.should == '78.54.172.146 - - [01/Jan/2012:16:30:51 -0800] "GET /package/core/oneiric/main/base/abrowser-6.0  HTTP/1.1" 200 6801 "http://www.google.com/url?sa=t&rct=j&q=abrowser 6.0&esrc=s&source=web&cd=4&sqi=2&ved=0CDYQFjAD&url=http%3A%2F%2Fwww.ubuntuupdates.org%2Fpackages%2Fshow%2F268762&ei=s-QlT8vJFon1sgb54unBDg&usg=AFQjCNHCHC0bxTf6aXAfUwT6Erjta6WLaQ&sig2=ceCi1odtaB8Vcf6IWg2a3w" "Mozilla/5.0 (Ubuntu; X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"'
      lines.last.should == '66.249.67.176 - - [01/Jan/2012:00:57:47 -0800] "GET /packages/show/1 HTTP/1.1" 301 185 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
    end

    it 'each_parsed_line should enumerate each line backwards' do
      records = []
      @alf.each_parsed_line(LineParser::AccessLog) do |record|
        records << record
      end

      records.first.time.should == Time.new(2012, 01, 01, 16, 30, 51, '-08:00')
      records.first.code.should == '200'
      records.last.time.should  == Time.new(2012, 01, 01, 00, 57, 47, '-08:00')
      records.last.code.should == '301'
    end
  end
end
