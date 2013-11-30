require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/timing_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe IntervalBuilder do
    before :each do
      @logfiles = ["#{data_dir}/timing.log", "#{data_dir}/timing.log.1" ]
      @set = LogfileSet.new(@logfiles, LineParser::TimingLog)
      @builder = IntervalBuilder.new(@set, 300)
    end

    context :each_interval do
      before :each do
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,0,'-08:00'))
        @intervals = []
        @builder.each_interval do |interval|
          @intervals << interval
        end
      end

      it 'finds intervals from all logfiles' do
        @intervals.size.should == 2
      end

      context 'first interval' do
        it 'got records from both logfiles' do
          @intervals.first.size.should == 4
          @intervals.first[:total_time].should == 700.0/4
          @intervals.first[:num_bytes].should == 52000
          @intervals.first[:action]['posts#index'] = 1
          @intervals.first[:action]['posts#create'] = 1
          @intervals.first[:action]['posts#show'] = 2
        end
      end

      context 'second interval' do
        it 'got records from second logfile only' do
          @intervals.last.size.should == 2
          @intervals.last[:total_time].should == 300
          @intervals.last[:num_bytes].should == 41000
          @intervals.last[:action]['posts#index'] = 1
          @intervals.last[:action]['posts#show'] = 1
        end
      end
    end
  end
end
