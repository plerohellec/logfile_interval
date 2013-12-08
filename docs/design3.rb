module LogfileInterval
  module LineParser
    class Base
      class << self
        def set_regex(regex)
        end

        def add_column(name, options)
          aggregator = Aggregators.klass(agg_function)
          @columns[name] = { :pos => pos, :agg_function => aggregator, :conversion => conversion }
          define_method(name)
        end

        def parse(line)
          match_data = regex.match(line)
          @data = f(match_data)
        end

        def create_record(line)
          record = new(line)
          return record.valid? ? record : nil
        end
      end

    end

    class AccessLog < Base
      set_regex /blah/
      add_column :name => :foo, :pos => 1, :conversion => integer, :agg_function => :average

      def initialize(line)
        @data = self.class.parse(line)
      end
    end

    module Aggregator
      def self.klass(agg_function)
        case agg_function
        when :sum then Sum
        end
      end

      class Sum
        def initialize
          @val = 0
        end

        def add(value)
          @val += value
        end

        def value
          @val
        end
      end

      class Count
        def initialize
          @val = Counter.new
        end

        def add(value)
          @val.increment(value)
        end
      end
    end
  end

  class Logfile
    def initialize(filename, parser)
    end

    def each_line
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

    def ordered_filenams
    end

    def each_line
    end

    def each_parsed_line
    end
  end

  class IntervalBuilder
    def initialize(logfile_set, length)
      parser = logfile_set.parser
    end

    def each_interval
      interval = Interval.new(now, length)
      set.each_parsed_line(parser) do |record|
        while record.time < interval.start_time do
          yield interval
          interval = Interval.new(interval.start_time, length)
        end
        interval.add(record)
      end
    end
  end

  class Counter < Hash
    def increment(key)
      self[key] = self[key] ? self[key] + 1 : 1
    end
  end

  class Interval
    def initialize(end_time, length, parser)
      @data = {}
      parser.columns.each do |name, options|
        @data[name] = options[:aggregator].new
      end
    end

    def [](name)
      @data[name].value
    end

    def add_record(record)
      return unless record.valid?
      raise ParserMismatch unless record.class == parser

      @size += 1
      parser.columns.each do |name, options|
        @data[name].add(record[name])
      end
    end
  end
end

logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
logfile = logfiles.first

parser = LineParser::AccessLog

logfile_iterator = LogfileInterval::Logfile.new(logfile, parser)
logfile_iterator.each_line do |line|
  puts line.class # String
  puts line
end

parser = LineParser::AccessLog
logfile_iterator.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
  puts record.ip
  puts record.time
end

set_iterator = LogfileInterval::LogfileSet.new(logfiles, parser)
set_iterator.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
end

length = 5.minutes
interval_builder = LogfileInterval::IntervalBuilder.new(logfiles, length)
interval_builder.each_interval do |interval|
  puts interval.class  # LogfileInterval::Interval
  puts interval.start_time
  puts interval.length
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
end
