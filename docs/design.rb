module LogfileInterval
  module ParsedLine

    module Parser
      def columns
        @columns ||= {}
      end

      def set_regex
      end

      def add_column
        agg = Aggregator::Base.klass(aggregator)
        @columns[name] = { :pos => pos, :aggregator => agg, :conversion => conversion }
        define_method(name)
      end

      def parse(line)
        match_data = regex.match(line)
        data = {}
        data = f(match_data)
      end

      def each(&block)
        columns.each(&block)
      end
    end

    class Base
      extend Parser

      def initialize(line)
        @data = self.class.parse(line)
      end
    end
  end

  class AggregatorSet
    def initialize(parser_columns)
      @aggregators = {}
      parser_columns.each do |name, options|
        @aggregators[name] = options[:aggregator].new(options)
      end
    end

    def add(record)
      @aggregators.each do |name, agg|
        agg.add_record(record)
      end
    end

    def each
      @aggregators.each do |name, agg|
        yield name, agg
      end
    end
  end

  class Interval
    def initialize(end_time, length, parser_columns)
      @aggregators = AggregatorSet.new(parser_columns)
    end

    def [](name)
      @aggregators[name].value
    end

    def add(record)
      @size += 1
      @aggregators.add_record(record)
    end
  end

  class IntervalBuilder
    def initialize(parsed_lines_enum, parser_columns, length)
    end

    def each_interval
      interval = Interval.new(now, length, parser_columns)
      parsed_lines_enum.each do |record|
        while record.time < interval.start_time do
          yield interval
          interval = Interval.new(interval.start_time, length, aggregators)
        end
        interval.add(record)
      end
    end
  end

  module Aggregator
    class Base
      def self.register(name, klass)
        @aggregator_classes[name] = klass
      end

      def self.klass(name)
        @aggregator_classes.fetch(name)
      end
    end

    class Sum < Base
      register :sum, self

      def initialize
        @val = 0
      end

      def add(value)
        @val += value
      end
    end

    class Count < Base
      def initialize
        @val = Counter.new
      end

      def add(value)
        @val.increment(value)
      end
    end
  end

  class Logfile
    def initialize(filename, parser)
    end

    def each_line
      return enum_for(:each_line) unless block_given?
      ...
    end

    def each_parsed_line
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
  end

  class LogfileSet
    def initialize(filenames_array, parser)
    end

    def ordered_filenames
    end

    def each_line
    end

    def each_parsed_line
    end
  end

  class Counter < Hash
    def increment(key)
      self[key] = self[key] ? self[key] + 1 : 1
    end
  end
end

class AccessLogParsedLine < LogfileInterval::Parse::Base
  set_regex /blah/
  add_column :name => :foo, :pos => 1, :conversion => integer, :aggregator => :average
end


logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
logfile = logfiles.first

parser = AccessLogParsedLine

logfile_iterator = LogfileInterval::Logfile.new(logfile, parser)
logfile_iterator.each_line do |line|
  puts line.class # String
  puts line
end

logfile_iterator.each_parsed_line do |record|
  puts record.class # ParsedLine::AccessLog
  puts record.ip
  puts record.time
end

set = LogfileInterval::LogfileSet.new(logfiles, parser)
set.each_parsed_line do |record|
  puts record.class # ParsedLine::AccessLog
end

length = 5.minutes
interval_builder = LogfileInterval::IntervalBuilder.new(set.each_parsed_line, parser, length)
interval_builder.each_interval do |interval|
  puts interval.class  # LogfileInterval::Interval
  puts interval.start_time
  puts interval.length
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
end
