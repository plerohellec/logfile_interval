require 'spec_helper'

module LogfileInterval
  describe AccessInterval do
    before :all do
      @file1 = File.join(File.dirname(__FILE__), '..', 'support/logfiles/access.log.1')
      @file2 = File.join(File.dirname(__FILE__), '..', 'support/logfiles/access.log.2')
      @end_time = Time.new(2013,06,23,17,0,0,'-08:00')
      @length = 5 * 60
    end

    it 'adds up counters on each line' do
      ai = AccessInterval.new(@end_time, @length)
      al = AccessLine.new '66.249.67.176 - - [23/Jun/2013:16:59:55 -0800] "GET /packages/show/1 HTTP/1.1" 301 185 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
      ai.add(al.parse)

      ai.ips['1.1.1.1'].should be_nil
      ai.ips['66.249.67.176'].should == 1
      ai.codes[200].should be_nil
      ai.codes[301].should == 1

      al = AccessLine.new '66.249.67.176 - - [23/Jun/2013:16:59:55 -0800] "GET /packages/show/1 HTTP/1.1" 200 185 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
      ai.add(al.parse)

      ai.ips['1.1.1.1'].should be_nil
      ai.ips['66.249.67.176'].should == 2
      ai.codes[200].should == 1
      ai.codes[301].should == 1
    end

    it 'raises exception for lines out of interval' do
      ai = AccessInterval.new(@end_time, @length)
      al = AccessLine.new '66.249.67.176 - - [23/Jun/2013:16:54:55 -0800] "GET /packages/show/1 HTTP/1.1" 301 185 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
      lambda { ai.add(al.parse) }.should raise_error(Interval::OutOfRange)
    end

    context 'each_interval_backward' do
      before :all do
        Time.stub(:now).and_return(Time.new(2013,06,23,17,1,0,'-08:00'))
        @intervals = []
        AccessInterval.each_interval_backward([@file1, @file2], @length) do |interval|
          @intervals << interval
        end
      end

      it 'reads all files it is given' do
        @intervals.size.should == 3
        @intervals.inject(0) { |total, interval| total += interval.size }.should == 4
      end

      it 'silently ignores files that do not exist' do
        intervals = []
        Time.stub(:now).and_return(Time.new(2013,06,23,17,1,0,'-08:00'))
        AccessInterval.each_interval_backward([@file1, @file2, 'foobar'], @length) do |interval|
          intervals << interval
        end
        intervals.size.should == 3
      end

      it 'builds interval across 2 files' do
        @intervals.first.size.should ==3
        @intervals.last.size.should ==1
      end

      it 'returns an interval even if there is no data between 2 other intervals' do
        @intervals[1].size.should == 0
      end

      it 'does an empty interval for segment following last bit of data and now' do
        intervals = []
        Time.stub(:now).and_return(Time.new(2013,06,23,17, 11,0,'-08:00'))
        AccessInterval.each_interval_backward([@file1], @length) do |interval|
          intervals << interval
        end
        intervals.size.should == 3
        intervals.first.size.should == 0
      end
    end
  end
end
