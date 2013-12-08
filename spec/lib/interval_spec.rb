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
      interval[:action].should == 0
    end

    context :add_record do
      before :each do
        @end_time = Time.new(2013, 12, 01, 16, 00, 00, '-08:00')
        @length = 300
      end

      context 'basics' do
        before :each do
          @interval = Interval.new(@end_time, @length, LineParser::TimingLog)
        end

        it 'rejects record out of interval' do
          oor_record = LineParser::TimingLog.create_record('1385942450, posts#index, 100, 20000, 50.0')
          lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
        end

        it 'rejects record at interval start_time' do
          oor_record = LineParser::TimingLog.create_record('1385942100, posts#index, 100, 20000, 50.0')
          lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
        end

        it 'adds 1 record to interval' do
          record1 = LineParser::TimingLog.create_record('1385942400, posts#index, 100, 20000, 50.0')
          @interval.add_record(record1)

          @interval.size.should == 1
          @interval[:total_time].should == 100
          @interval[:num_bytes].should == 20000
          @interval[:action].should == 1
        end
      end

      context 'with 3 records' do
        before :each do
          @interval = Interval.new(@end_time, @length, LineParser::TimingLog)

          record1 = LineParser::TimingLog.create_record('1385942400, posts#index, 100, 20000, 53.0')
          @interval.add_record(record1)
          record2 = LineParser::TimingLog.create_record('1385942300, posts#show, 50, 10000, 51.0')
          @interval.add_record(record2)
          record3 = LineParser::TimingLog.create_record('1385942200, posts#show, 60, 12000, 50.0')
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

        it 'averages the delta columns with delta agg_function' do
          @interval[:rss].should == 1.5
        end

        it 'counts columns with group agg_function' do
          @interval[:action].should == 3
        end
      end

      context 'with group_by key' do
        before :each do
          @interval = Interval.new(@end_time, @length, LineParser::TimingLogWithGrouping)

          record1 = LineParser::TimingLogWithGrouping.create_record('1385942400, posts#index, 100, 20000, 53.0')
          @interval.add_record(record1)
          record2 = LineParser::TimingLogWithGrouping.create_record('1385942300, posts#show, 50, 10000, 51.0')
          @interval.add_record(record2)
          record3 = LineParser::TimingLogWithGrouping.create_record('1385942200, posts#show, 60, 12000, 50.0')
          @interval.add_record(record3)
          record4 = LineParser::TimingLogWithGrouping.create_record('1385942180, posts#index, 100, 20000, 48.0')
          @interval.add_record(record4)
        end

        it 'count value column per group column' do
          @interval[:action].should be_a(Hash)
          @interval[:action].size.should == 2
          @interval[:action]['posts#index'].should == 2
          @interval[:action]['posts#show'].should  == 2
        end

        it 'averages value column per group column' do
          @interval[:total_time].should be_a(Hash)
          @interval[:total_time].size.should == 2
          @interval[:action]['posts#index'].should == 2
          @interval[:action]['posts#show'].should  == 2
          @interval[:total_time]['posts#index'].should == 100
          @interval[:total_time]['posts#show'].should  == 55
        end

        it 'sums up value column per group column' do
          @interval[:num_bytes].should be_a(Hash)
          @interval[:num_bytes].size.should == 2
          @interval[:num_bytes]['posts#index'].should == 40000
          @interval[:num_bytes]['posts#show'].should  == 22000
        end

        it 'averages deltas on value column per group column' do
          @interval[:rss].should be_a(Hash)
          @interval[:rss].size.should == 2
          @interval[:rss]['posts#index'].should == 5
          @interval[:rss]['posts#show'].should  == 1
        end
      end
    end
  end
end
