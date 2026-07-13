require 'spec_helper'
require 'tempfile'

module LogfileInterval
  describe IntervalBuilder do

    # JSON equivalent of the TimingLog parser, using :key instead of :pos
    class JsonTimingLog < ParsedLine::Json
      add_column :name => :timestamp,  :key => 'timestamp',  :aggregator => :timestamp
      add_column :name => :num_lines,  :key => 'ip',         :aggregator => :num_lines
      add_column :name => :ip,         :key => 'ip',         :aggregator => :count
      add_column :name => :action,     :key => 'action',     :aggregator => :count
      add_column :name => :total_time, :key => 'total_time', :aggregator => :average,   :conversion => :integer
      add_column :name => :num_bytes,  :key => 'num_bytes',  :aggregator => :sum,       :conversion => :integer
      add_column :name => :rss,        :key => 'rss',        :aggregator => :delta,     :conversion => :float

      def time
        Time.at(self.timestamp.to_i)
      end
    end

    # Helper: create a temp directory with JSON log files matching the timing.log data
    def create_json_logfiles(data_map)
      dir = Dir.mktmpdir('json_timing')
      files = data_map.map do |filename, lines|
        path = File.join(dir, filename)
        File.open(path, 'w') do |f|
          lines.each { |line| f.puts(line.to_json) }
        end
        path
      end
      [dir, files]
    end

    # JSON lines equivalent to timing.log content
    let(:json_log_lines) do
      [
        { timestamp: '1385942280', ip: '192.168.0.10', action: 'posts#index', total_time: '100', num_bytes: '20000', rss: '50.20' },
        { timestamp: '1385942340', ip: '192.168.0.5',  action: 'posts#create', total_time: '200', num_bytes: '5000',  rss: '50.20' },
        { timestamp: '1385942400', ip: '192.168.0.5',  action: 'posts#show',   total_time: '100', num_bytes: '15000', rss: '51.00' },
      ]
    end

    # JSON lines equivalent to timing.log.1 content
    let(:json_log_1_lines) do
      [
        { timestamp: '1385941980', ip: '192.168.0.5',  action: 'posts#show',   total_time: '100', num_bytes: '16000', rss: '48.00' },
        { timestamp: '1385942040', ip: '192.168.0.10', action: 'posts#index',  total_time: '500', num_bytes: '25000', rss: '48.20' },
        { timestamp: '1385942160', ip: '192.168.0.5',  action: 'posts#show',   total_time: '300', num_bytes: '12000', rss: '49.20' },
      ]
    end

    # JSON lines equivalent to timing.log.2 content
    let(:json_log_2_lines) do
      [
        { timestamp: '1385941440', ip: '192.168.0.5',  action: 'posts#show',   total_time: '100', num_bytes: '16000', rss: '48.00' },
      ]
    end

    after :each do
      # Clean up temp directory
      FileUtils.remove_entry(@tmp_dir) if @tmp_dir
    end

    describe 'initialization' do
      it 'accepts a Logfile as the parsed_lines_enum argument' do
        @tmp_dir, (path,) = create_json_logfiles({ 'timing.json' => json_log_lines })
        logfile = Logfile.new(path, JsonTimingLog)
        builder = IntervalBuilder.new(logfile, JsonTimingLog, 300)
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        intervals = []
        builder.each_interval do |interval|
          intervals << interval
        end
        intervals.size.should == 1
      end

      it 'accepts a LogfileSet as the parsed_lines_enum argument' do
        @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines, 'timing.json.1' => json_log_1_lines })
        set = LogfileSet.new(paths, JsonTimingLog)
        builder = IntervalBuilder.new(set, JsonTimingLog, 300)
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        intervals = []
        builder.each_interval do |interval|
          intervals << interval
        end
        intervals.size.should == 2
      end
    end

    describe :boundary_offset do
      it 'returns the start of the interval on a round boundary' do
        @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines })
        set = LogfileSet.new(paths, JsonTimingLog)
        builder = IntervalBuilder.new(set, JsonTimingLog, 60)
        expect(builder.start_boundary_time(Time.new(2013,12,01,16,0,1))).to eql(Time.new(2013,12,01,16,0,0))
      end

      it 'first interval is aligned on round boundary' do
        Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
        @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines })
        set = LogfileSet.new(paths, JsonTimingLog)
        builder = IntervalBuilder.new(set, JsonTimingLog, 3600)
        builder.first_interval.start_time.should == Time.new(2013,12,01,15,0,0,'-08:00')
      end

      context 'with offset' do
        it 'returns the start of the interval on an offset boundary' do
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines })
          set = LogfileSet.new(paths, JsonTimingLog)
          builder = IntervalBuilder.new(set, JsonTimingLog, 60, boundary_offset: 5)
          expect(builder.start_boundary_time(Time.new(2013,12,01,16,0,1))).to eql(Time.new(2013,12,01,15,59,05))
        end

        it 'first interval is aligned on round boundary' do
          Time.stub(:now).and_return(Time.new(2013,12,01,17,1,1,'-08:00'))
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines })
          set = LogfileSet.new(paths, JsonTimingLog)
          builder = IntervalBuilder.new(set, JsonTimingLog, 3600, boundary_offset: 300)
          builder.first_interval.start_time.should == Time.new(2013,12,01,15,05,0,'-08:00')
          builder = IntervalBuilder.new(set, JsonTimingLog, 3600, boundary_offset: 60)
          builder.first_interval.start_time.should == Time.new(2013,12,01,16,01,0,'-08:00')
        end
      end
    end

    describe :each_interval do
      context 'without a block' do
        it 'returns an enumerator' do
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines })
          set = LogfileSet.new(paths, JsonTimingLog, :desc)
          builder = IntervalBuilder.new(set, JsonTimingLog, 300)
          e = builder.each_interval
          e.should be_a(Enumerator)
        end
      end

      context 'with empty logfiles' do
        it 'does not yield any interval' do
          @tmp_dir, paths = create_json_logfiles({ 'empty.json' => [] })
          set = LogfileSet.new(paths, JsonTimingLog)
          builder = IntervalBuilder.new(set, JsonTimingLog, 300)
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
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines, 'timing.json.1' => json_log_1_lines })
          @set = LogfileSet.new(paths, JsonTimingLog, :desc)
          @builder = IntervalBuilder.new(@set, JsonTimingLog, 300)
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
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines, 'timing.json.1' => json_log_1_lines })
          @set = LogfileSet.new(paths, JsonTimingLog, :asc)
          @builder = IntervalBuilder.new(@set, JsonTimingLog, 300)
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
          @tmp_dir, @paths = create_json_logfiles({
            'timing.json'   => json_log_lines,
            'timing.json.1' => json_log_1_lines,
            'timing.json.2' => json_log_2_lines,
          })
        end

        context 'in descending order' do
          before :each do
            @set = LogfileSet.new(@paths, JsonTimingLog, :desc)
            @builder = IntervalBuilder.new(@set, JsonTimingLog, 300)
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
            @set = LogfileSet.new(@paths, JsonTimingLog, :asc)
            @builder = IntervalBuilder.new(@set, JsonTimingLog, 300)
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
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines, 'timing.json.1' => json_log_1_lines })
          set = LogfileSet.new(paths, JsonTimingLog, :asc)
          builder = IntervalBuilder.new(set, JsonTimingLog, 300)
          interval = builder.first_interval
          interval.end_time.should == Time.new(2013,12,01,15,55,0,'-08:00')
          interval.size.should == 2
        end
      end

      context 'with parsed_lines_enum in descending order' do
        it 'returns the most recent interval' do
          Time.stub(:now).and_return(Time.new(2013,12,01,16,0,1,'-08:00'))
          @tmp_dir, paths = create_json_logfiles({ 'timing.json' => json_log_lines, 'timing.json.1' => json_log_1_lines })
          set = LogfileSet.new(paths, JsonTimingLog, :desc)
          builder = IntervalBuilder.new(set, JsonTimingLog, 300)
          interval = builder.first_interval
          interval.end_time.should == Time.new(2013,12,01,16,0,0,'-08:00')
          interval.size.should == 4
        end
      end
    end
  end
end
