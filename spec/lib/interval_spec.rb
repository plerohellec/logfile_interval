require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/timing_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe Interval do
    before :each do
      @end_time = Time.new(2013, 12, 01, 16, 00, 00, '-08:00')
      @length = 300
    end

    it 'gets instantiated with empty data' do
      interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)
      interval.size.should == 0
      interval[:total_time].should == 0
      interval[:num_bytes].should == 0
      interval[:action].should == 0
      interval[:ip].should == 0
    end

    context :to_hash do
      it 'returns a hash' do
        interval = Interval.new(@end_time, @length, ParsedLine::TimingLog)
        interval.to_hash.should be_a(Hash)
      end

      it 'has a key for all columns' do
        record   = ParsedLine::TimingLog.create_record('1385942400, 192.168.0.5, posts#index, 100, 2000, 53.0')
        interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)
        interval.add_record(record)
        hinterval = interval.to_hash
        hinterval.keys.should include(:ip, :total_time, :action, :num_bytes, :rss)
      end

      it 'has start_time and end_time keys' do
        record   = ParsedLine::TimingLog.create_record('1385942400, 192.168.0.5, posts#index, 100, 2000, 53.0')
        interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)
        interval.add_record(record)
        hinterval = interval.to_hash
        hinterval.keys.should include(:start_time, :end_time)
      end

      it 'with no data, should have keys with 0 values' do
        interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)
        hinterval = interval.to_hash
        hinterval[:num_lines].should == 0
        hinterval[:ip].should == 0
        hinterval[:action].should == 0
        hinterval[:total_time].should == 0
        hinterval[:num_bytes].should == 0
        hinterval[:rss].should == 0
      end
    end

    context :add_record do
      context 'basics' do
        before :each do
          @interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)
        end

        it 'rejects record out of interval' do
          oor_record = ParsedLine::TimingLog.create_record('1385942450, 192.168.0.5, posts#index, 100, 20000, 50.0')
          lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
        end

        it 'rejects record at interval start_time' do
          oor_record = ParsedLine::TimingLog.create_record('1385942100, 192.168.0.5, posts#index, 100, 20000, 50.0')
          lambda { @interval.add_record(oor_record) }.should raise_error(Interval::OutOfRange)
        end

        it 'accepts record at interval end_time' do
          oor_record = ParsedLine::TimingLog.create_record('1385942400, 192.168.0.5, posts#index, 100, 20000, 50.0')
          lambda { @interval.add_record(oor_record) }.should_not raise_error
        end

        it 'adds 1 record to interval' do
          record1 = ParsedLine::TimingLog.create_record('1385942400, 192.168.0.5, posts#index, 100, 20000, 50.0')
          @interval.add_record(record1)

          @interval.size.should == 1
          @interval[:num_lines].should == 1
          @interval[:total_time].should == 100
          @interval[:num_bytes].should == 20000
          @interval[:action].should == {"posts#index"=>1}
          @interval[:ip].should == {"192.168.0.5"=>1}
        end
      end

      context 'with count and group by options' do
        it 'creates an aggregator of type Count' do
          expect(Aggregator::Count).to receive(:new).twice
          interval = Interval.new(@end_time, @length, ParsedLine::TimingLogWithGrouping.columns)
        end

        it 'add_record accepts key and subkey' do
          interval = Interval.new(@end_time, @length, ParsedLine::TimingLogWithGrouping.columns)
          record1 = ParsedLine::TimingLogWithGrouping.create_record('1385942400, 192.168.0.5, posts#index, 100, 20000, 53.0')
          interval.add_record(record1)
          interval.size.should == 1
        end
      end

      context 'with 3 records' do
        before :each do
          @interval = Interval.new(@end_time, @length, ParsedLine::TimingLog.columns)

          record1 = ParsedLine::TimingLog.create_record('1385942400, 192.168.0.5, posts#index, 100, 20000, 53.0')
          @interval.add_record(record1)
          record2 = ParsedLine::TimingLog.create_record('1385942300, 192.168.0.5, posts#show, 50, 10000, 51.0')
          @interval.add_record(record2)
          record3 = ParsedLine::TimingLog.create_record('1385942200, 10.10.10.10, posts#show, 60, 12000, 50.0')
          @interval.add_record(record3)
        end

        it 'increments size' do
          @interval.size.should == 3
        end

        it 'counts the number of lines with the num_lines aggregator' do
          @interval[:num_lines].should == 3
        end

        it 'averages columns with average aggregator' do
          @interval[:total_time].should == 70
        end

        it 'sums up columns with sum aggregator' do
          @interval[:num_bytes].should == 42000
        end

        it 'averages the delta columns with delta aggregator' do
          @interval[:rss].should == -1.5
        end

        it 'counts columns with group aggregator' do
          @interval[:ip].should ==  { '192.168.0.5' => 2, '10.10.10.10' => 1 }
          @interval[:action].should == { 'posts#index' => 1, 'posts#show' => 2}
        end
      end

      context 'with group_by key' do
        before :each do
          @interval = Interval.new(@end_time, @length, ParsedLine::TimingLogWithGrouping.columns)

          record1 = ParsedLine::TimingLogWithGrouping.create_record('1385942400, 192.168.0.5, posts#index, 100, 20000, 53.0')
          @interval.add_record(record1)
          record2 = ParsedLine::TimingLogWithGrouping.create_record('1385942300, 192.168.0.5, posts#show, 50, 10000, 51.0')
          @interval.add_record(record2)
          record3 = ParsedLine::TimingLogWithGrouping.create_record('1385942200, 192.168.0.5, posts#show, 60, 12000, 50.0')
          @interval.add_record(record3)
          record4 = ParsedLine::TimingLogWithGrouping.create_record('1385942180, 10.10.10.10, posts#index, 100, 20000, 48.0')
          @interval.add_record(record4)
        end

        it 'counts value column per group column' do
          @interval[:action].should be_a(Hash)
          @interval[:action].size.should == 2
          @interval[:action]['posts#index'].should == 2
          @interval[:action]['posts#show'].should  == 2
        end

        it 'counts value and group_by pairs' do
          @interval[:ip_by_action].should be_a(Hash)
          @interval[:ip_by_action]['192.168.0.5'].should be_a(Hash)
          @interval[:ip_by_action]['192.168.0.5']['posts#index'].should == 1
          @interval[:ip_by_action]['192.168.0.5']['posts#show'].should  == 2
          @interval[:ip_by_action]['10.10.10.10']['posts#index'].should == 1
        end

        it 'averages value column per group column' do
          @interval[:total_time].should be_a(Hash)
          @interval[:total_time].size.should == 2
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
          @interval[:rss]['posts#index'].should == -5
          @interval[:rss]['posts#show'].should  == -1
        end
      end
    end
  end
end
