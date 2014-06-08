require 'spec_helper'

require File.join(File.dirname(__FILE__), '..', 'support/lib/timing_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe IntervalBuilder do
    before :each do
      @logfiles = ["#{data_dir}/timing.log", "#{data_dir}/timing.log.1" ]
    end

    describe 'initialization' do
      before :each do
        @set = LogfileSet.new(@logfiles, ParsedLine::TimingLog)
        @builder = IntervalBuilder.new(@set.each_parsed_line, ParsedLine::TimingLog, 300)
      end

      it 'accepts a logfile as the parsed_lines_enum argument' do
        logfile = Logfile.new("#{data_dir}/timing.log", ParsedLine::TimingLog)
        builder = IntervalBuilder.new(logfile, ParsedLine::TimingLog, 300)
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        intervals = []
        builder.each_interval do |interval|
          intervals << interval
        end
        intervals.size.should == 1
      end

      it 'accepts a logfile_set as the parsed_lines_enum argument' do
        builder = IntervalBuilder.new(@set, ParsedLine::TimingLog, 300)
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        intervals = []
        builder.each_interval do |interval|
          intervals << interval
        end
        intervals.size.should == 2
      end
    end

    describe :start_boundary_time do
      it 'returns the start of the interval on a round boundary' do
        set = LogfileSet.new(@logfiles, ParsedLine::TimingLog)
        builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 60)
        expect(builder.start_boundary_time(Time.new(2013,12,01,16,0,1))).to eql(Time.new(2013,12,01,16,0,0))
      end

      it 'first interval is aligned on round boundary' do
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        set = LogfileSet.new(@logfiles, ParsedLine::TimingLog)
        builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 3600)
        builder.first_interval.start_time.should == Time.new(2013,12,01,15,0,0,'-08:00')
      end

      context 'with offset' do
        it 'returns the start of the interval on an offset boundary' do
          set = LogfileSet.new(@logfiles, ParsedLine::TimingLog)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 60, offset: 5)
          expect(builder.start_boundary_time(Time.new(2013,12,01,16,0,1))).to eql(Time.new(2013,12,01,15,59,05))
        end

        it 'first interval is aligned on round boundary' do
          Time.stub(:now).and_return(Time.new(2013,12,01,17,1,1,'-08:00'))
          set = LogfileSet.new(@logfiles, ParsedLine::TimingLog)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 3600, offset: 300)
          builder.first_interval.start_time.should == Time.new(2013,12,01,15,05,0,'-08:00')
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 3600, offset: 60)
          builder.first_interval.start_time.should == Time.new(2013,12,01,16,01,0,'-08:00')
        end
      end
    end

    describe :each_interval do
      context 'without a block' do
        it 'returns an enumerator' do
          set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :desc)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 300)
          e = builder.each_interval
          e.should be_a(Enumerator)
        end
      end

      context 'with empty logfiles' do
        it 'does not yield any interval' do
          logfiles = ["#{data_dir}/non_existing_timing.log", "#{data_dir}/non_existing_timing.log.1" ]
          set = LogfileSet.new(logfiles, ParsedLine::TimingLog)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 300)
          intervals = []
          builder.each_interval do |interval|
            intervals << interval
          end
          intervals.should be_empty
        end
      end

      context 'in descending order' do
        before :each do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          @set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :desc)
          @builder = IntervalBuilder.new(@set, ParsedLine::TimingLog, 300)
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
            @intervals.first.end_time.should == Time.new(2013,12,01,16,0,0,'-08:00')
            @intervals.first[:total_time].should == 700.0/4
            @intervals.first[:num_bytes].should == 52000
            @intervals.first[:rss].round(5).should == -0.60
            @intervals.first[:ip].should == {"192.168.0.5"=>3, "192.168.0.10"=>1}
            @intervals.first[:action].should == {"posts#show"=>2, "posts#create"=>1, "posts#index"=>1}
          end
        end

        context 'second interval' do
          it 'got records from second logfile only' do
            @intervals.last.size.should == 2
            @intervals.last.end_time.should == Time.new(2013,12,01,15,55,0,'-08:00')
            @intervals.last[:total_time].should == 300
            @intervals.last[:num_bytes].should == 41000
            @intervals.last[:rss].round(5).should == -0.20
            @intervals.last[:ip].should == {"192.168.0.10"=>1, "192.168.0.5"=>1}
            @intervals.last[:action].should == {"posts#index"=>1, "posts#show"=>1}
          end
        end
      end

      context 'in ascending order' do
        before :each do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          @intervals = []
          @set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :asc)
          @builder = IntervalBuilder.new(@set, ParsedLine::TimingLog, 300)
          @builder.each_interval do |interval|
            @intervals << interval
          end
        end

        it 'builds first interval older than last interval' do
          first_time = @intervals.first.start_time
          last_time  = @intervals.last.start_time
          first_time.should be < last_time
        end

        it 'builds first interval with start time at 5 minute boundary below first record' do
          first_start_time = @intervals.first.start_time
          first_start_time.should == Time.new(2013,12,01,15,50,0,'-08:00')
        end

        it 'builds last interval with end time at 5 minute boundary following last record' do
          last_end_time = @intervals.last.end_time
          last_end_time.should == Time.new(2013,12,01,16,0,0,'-08:00')
        end

        it 'puts the right data in the right intervals' do
          @intervals.first.size.should == 2
          @intervals.first.end_time.should == Time.new(2013,12,01,15,55,0,'-08:00')
          @intervals.first[:total_time].should == 300
          @intervals.first[:num_bytes].should == 41000
          @intervals.first[:rss].round(5).should == 0.20
          @intervals.first[:ip].should == {"192.168.0.10"=>1, "192.168.0.5"=>1}
          @intervals.first[:action].should == {"posts#index"=>1, "posts#show"=>1}

          @intervals.last.size.should == 4
          @intervals.last.end_time.should == Time.new(2013,12,01,16,0,0,'-08:00')
          @intervals.last[:total_time].should == 700.0/4
          @intervals.last[:num_bytes].should == 52000
          @intervals.last[:rss].round(5).should == 0.60
          @intervals.last[:ip].should == {"192.168.0.5"=>3, "192.168.0.10"=>1}
          @intervals.last[:action].should == {"posts#show"=>2, "posts#create"=>1, "posts#index"=>1}
        end
      end

      context 'with a gap in the logfiles' do
        before :each do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          @logfiles = ["#{data_dir}/timing.log", "#{data_dir}/timing.log.1", "#{data_dir}/timing.log.2" ]
        end

        context 'in descending order' do
          before :each do
            @set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :desc)
            @builder = IntervalBuilder.new(@set, ParsedLine::TimingLog, 300)
            @intervals = []
            @builder.each_interval do |interval|
              @intervals << interval
            end
          end

          it 'creates an empty interval' do
            @intervals.size.should == 4
            gap_interval = @intervals[2]
            gap_interval.size.should == 0
            gap_interval.end_time.should == Time.new(2013,12,01,15,50,0,'-08:00')
          end
        end

        context 'in ascending order' do
          before :each do
            @set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :asc)
            @builder = IntervalBuilder.new(@set, ParsedLine::TimingLog, 300)
            @intervals = []
            @builder.each_interval do |interval|
              @intervals << interval
            end
          end

          it 'creates an empty interval' do
            @intervals.size.should == 4
            gap_interval = @intervals[1]
            gap_interval.size.should == 0
            gap_interval.end_time.should == Time.new(2013,12,01,15,50,0,'-08:00')
          end
        end
      end
    end

    describe :first_interval do
      context 'with parsed_lines_enum in ascending order' do
        it 'returns the oldest interval' do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :asc)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 300)
          interval = builder.first_interval
          interval.end_time.should == Time.new(2013,12,01,15,55,0,'-08:00')
          interval.size.should == 2
        end
      end

      context 'with parsed_lines_enum in descending order' do
        it 'returns the most recent interval' do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          set = LogfileSet.new(@logfiles, ParsedLine::TimingLog, :desc)
          builder = IntervalBuilder.new(set, ParsedLine::TimingLog, 300)
          interval = builder.first_interval
          interval.end_time.should == Time.new(2013,12,01,16,0,0,'-08:00')
          interval.size.should == 4
        end
      end
    end
  end
end
