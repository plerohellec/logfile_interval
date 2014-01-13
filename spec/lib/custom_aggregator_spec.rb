require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/custom_timing_log')

module LogfileInterval
  describe 'Custom Aggregator' do
    before :each do
      @end_time = Time.new(2013, 12, 01, 16, 00, 00, '-08:00')
      @length = 300
      @line_parser_class = LineParser::CustomTimingLog
    end

    def fill_interval
      @interval = Interval.new(@end_time, @length, @line_parser_class)
      record1 = @line_parser_class.create_record('1385942400, 192.168.0.5, posts#index, 150, 20000, 53.0')
      @interval.add_record(record1)
      record2 = @line_parser_class.create_record('1385942300, 192.168.0.5, posts#show, 50, 10000, 51.0')
      @interval.add_record(record2)
      record3 = @line_parser_class.create_record('1385942200, 10.10.10.10, posts#show, 70, 12000, 50.0')
      @interval.add_record(record3)
    end

    it 'gets instantiated with empty data' do
      fill_interval

      @interval.size.should == 3
      @interval[:num_slow].should == 1
      @interval[:ip].should == 3
    end

    describe 'set_column_custom_options' do
      it 'overwrites custom aggregator custom options' do
        @line_parser_class.set_column_custom_options(:num_slow, :threshold => 60)
        fill_interval

        @interval.size.should == 3
        @interval[:num_slow].should == 2
        @interval[:ip].should == 3
      end
    end
  end
end
