require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/timing_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe Interval do
    it 'gets instantiated with empty data' do
      end_time = Time.new(2013, 12, 01, 16, 00, 00, '-08:00')
      interval = Interval.new(end_time, 300, LineParser::TimingLog)
      interval.size.should == 0
      interval[:total_time].should == 0
      interval[:num_bytes].should == 0
      interval[:action].should be_a(Hash)
    end

    context :add_record do
      before :each do
        @end_time = Time.new(2013, 12, 01, 16, 00, 00, '-08:00')
        @length = 300
        @interval = Interval.new(@end_time, @length, LineParser::TimingLog)
      end

      it 'rejects record out of interval' do
        oor_record = LineParser::TimingLog.create_record('1385942450, posts#index, 100, 20000')
        lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
      end

      it 'rejects record at interval start_time' do
        oor_record = LineParser::TimingLog.create_record('1385942100, posts#index, 100, 20000')
        lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
      end

      it 'adds 1 record to interval' do
        record1 = LineParser::TimingLog.create_record('1385942400, posts#index, 100, 20000')
        @interval.add_record(record1)

        @interval.size.should == 1
        @interval[:total_time].should == 100
        @interval[:num_bytes].should == 20000
        @interval[:action]['posts#index'].should == 1
      end

      context '3 records' do
        before :each do
          record1 = LineParser::TimingLog.create_record('1385942400, posts#index, 100, 20000')
          @interval.add_record(record1)
          record2 = LineParser::TimingLog.create_record('1385942300, posts#show, 50, 10000')
          @interval.add_record(record2)
          record3 = LineParser::TimingLog.create_record('1385942200, posts#show, 60, 12000')
          @interval.add_record(record3)
        end

        it 'increments size' do
          @interval.size.should == 3
        end

        it 'averages columns with average agg_function' do
          @interval[:total_time].should == 70
        end

        it 'sums up columns with sum agg_function' do
          @interval[:num_bytes].should == 42000
        end

        it 'groups and counts columns with group agg_function' do
          @interval[:action]['posts#index'].should == 1
          @interval[:action]['posts#show'].should == 2
        end
      end
    end
  end
end
