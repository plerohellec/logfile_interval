require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/access_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe LogfileSet do
    before :each do
      @logfiles = ["#{data_dir}/access.log.2", "#{data_dir}/access.log.1"]
      @set = LogfileSet.new(@logfiles, ParsedLine::AccessLog)
      @first_line = '66.249.67.176 - - [23/Jun/2013:17:00:01 -0800] "GET /package/core/raring/universe/proposed/openldap HTTP/1.1" 200 185 "-" "Google"'
      @second_line = '12.24.48.96 - - [23/Jun/2013:16:59:00 -0800] "GET /package/core/raring/universe/proposed/openldap HTTP/1.1" 200 4555 "-" "Bing)"'
      @last_line  = '12.24.48.96 - - [23/Jun/2013:16:49:00 -0800] "GET /package/core/raring/universe/proposed/bash HTTP/1.1" 200 4555 "-" "Bing)"'
    end

    describe :each_line do
      it 'should enumerate each line in file backwards' do
        lines = []
        @set.each_line do |line|
          lines << line
        end

        lines.first.should == @first_line
        lines.last.should  == @last_line
      end

      context 'without a block' do
        it 'should return an enumerator' do
          e = @set.each_line
          e.should be_a(Enumerator)
          e.first.should == @first_line
          e.next.should  == @first_line
          e.next.should  == @second_line
        end
      end

      context :order do
        it 'iterates backward when order is :desc' do
          lines = []
          set = LogfileSet.new(@logfiles, ParsedLine::AccessLog, :desc)
          set.each_line do |line|
            lines << line
          end
          lines.last.should  == @last_line
          lines.first.should == @first_line
        end

        it 'iterates upward when order is :asc' do
          lines = []
          set = LogfileSet.new(@logfiles, ParsedLine::AccessLog, :asc)
          set.each_line do |line|
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
        @set.each_parsed_line do |record|
          records << record
        end

        records.first.time.should == Time.new(2013, 06, 23, 17, 00, 01, '-08:00')
        records.first.code.should == '200'
        records.last.time.should  == Time.new(2013, 06, 23, 16, 49, 00, '-08:00')
        records.last.code.should == '200'
      end

      context 'without a block' do
        it 'should return an enumerator' do
          e = @set.each_parsed_line
          e.should be_a(Enumerator)
          e.next.time.should == Time.new(2013, 06, 23, 17, 00, 01, '-08:00')
        end
      end
    end

    describe :ordered_filenames do
      it 'returns the most recent file first' do
        @set.ordered_filenames.should == @logfiles.reverse
      end

      context 'with file_time_finder_block' do
        it 'sorts the files in the order described in the block' do
          set = LogfileSet.new(@logfiles, ParsedLine::AccessLog) do |filename|
            filename.match /(?<num>\d+$)/ do |matchdata|
              matchdata[:num].to_i
            end
          end
          set.ordered_filenames.should == @logfiles
        end
      end
    end
  end
end
