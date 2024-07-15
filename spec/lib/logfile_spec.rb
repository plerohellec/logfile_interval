require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/access_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe Logfile do
    before :each do
      @alf = Logfile.new("#{data_dir}/access.log", ParsedLine::AccessLog)
      @first_line = '78.54.172.146 - - [01/Jan/2024:16:30:51 -0800] "GET /package/core/oneiric/main/base/abrowser-6.0  HTTP/1.1" 200 6801 "http://www.google.com/url?sa=t&rct=j&q=abrowser 6.0&esrc=s&source=web&cd=4&sqi=2&ved=0CDYQFjAD&url=http%3A%2F%2Fwww.ubuntuupdates.org%2Fpackages%2Fshow%2F268762&ei=s-QlT8vJFon1sgb54unBDg&usg=AFQjCNHCHC0bxTf6aXAfUwT6Erjta6WLaQ&sig2=ceCi1odtaB8Vcf6IWg2a3w" "Mozilla/5.0 (Ubuntu; X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"'
      @second_line = '78.54.172.146 - - [01/Jan/2024:16:30:51 -0800] "GET /package/show/2  HTTP/1.1" 302 6801 "http://www.google.com/url?sa=t&rct=j&q=abrowser 6.0&esrc=s&source=web&cd=4&sqi=2&ved=0CDYQFjAD&url=http%3A%2F%2Fwww.ubuntuupdates.org%2Fpackages%2Fshow%2F268762&ei=s-QlT8vJFon1sgb54unBDg&usg=AFQjCNHCHC0bxTf6aXAfUwT6Erjta6WLaQ&sig2=ceCi1odtaB8Vcf6IWg2a3w" "Mozilla/5.0 (Ubuntu; X11; Linux x86_64; rv:9.0.1) Gecko/20100101 Firefox/9.0.1"'
      @last_line = '66.249.67.176 - - [01/Jan/2024:00:57:47 -0800] "GET /packages/show/1 HTTP/1.1" 301 185 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
    end

    it 'first_timestamp returns time of first line in file' do
      #01/Jan/2024:00:57:47 -0800
      @alf.first_timestamp.should == Time.new(2024, 01, 01, 00, 57, 47, '-08:00')
    end

    describe :each_line do
      it 'should enumerate each line in file backwards' do
        lines = []
        @alf.each_line do |line|
          lines << line
        end

        lines.first.should == @first_line
        lines.last.should  == @last_line
      end

      context 'without a block' do
        it 'should return an enumerator' do
          e = @alf.each_line
          e.should be_a(Enumerator)
          e.first.should == @first_line
          e.next.should  == @first_line
          e.next.should  == @second_line
        end
      end

      context :order do
        it 'iterates backward when order is :desc' do
          lines = []
          lf = Logfile.new("#{data_dir}/access.log", ParsedLine::AccessLog, :desc)
          lf.each_line do |line|
            lines << line
          end
          lines.last.should  == @last_line
          lines.first.should == @first_line
        end

        it 'iterates upward when order is :asc' do
          lines = []
          lf = Logfile.new("#{data_dir}/access.log", ParsedLine::AccessLog, :asc)
          lf.each_line do |line|
            lines << line
          end
          lines.first.should == @last_line
          lines.last.should  == @first_line
        end
      end
    end

    describe :each_parsed_line do
      it 'should enumerate each line backwards' do
        records = []
        @alf.each_parsed_line do |record|
          records << record
        end

        records.first.time.should == Time.new(2024, 01, 01, 16, 30, 51, '-08:00')
        records.first.code.should == '200'
        records.first.length.should == 6801
        records.first.length_by_ip.should == 6801
        records.last.time.should  == Time.new(2024, 01, 01, 00, 57, 47, '-08:00')
        records.last.code.should == '301'
        records.last.length.should == 185
        records.last.length_by_ip.should == 185
      end

      it 'skips lines matching skip options' do
        records = []
        @alf.each_parsed_line do |record|
          records << record
        end

        records.size.should == 6
      end

      context 'without a block' do
        it 'should return an enumerator' do
          e = @alf.each_parsed_line
          e.should be_a(Enumerator)
          e.next.time.should == Time.new(2024, 01, 01, 16, 30, 51, '-08:00')
        end
      end
    end
  end
end
