module LogfileInterval
  module LineParser
    class Base
      class << self
        def set_regex(regex)
        end

        def add_column(name, options)
          define_method(name)
        end

        def parse(line)
          @data = {}
          match_data = regex.match(line)
          columns.each do |name, options|
            val = match_data[options[:pos]]
            @data[name] = convert(val, options[:conversion])
          end
          @data
        end

        def create_record(line)
          record = new(line)
          return record.valid? ? record : nil
        end

        def convert(val, conversion)
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
  end

  class Logfile
    def initialize(filename)
    end

    def each_line
    end

    def each_parsed_line(parser)
      each_line do |line|
        record = parser.create_record(line)
        yield record if record
      end
    end
  end

  class LogfileSet
    def initialize(parser, filenames_array)
    end

    def ordered_filenams
    end

    def each_line
    end

    def each_parsed_line
    end
  end

  class IntervalBuilder
    def initialize(logfile_set, parser, length)
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
      @data = { :size => 0 }
      parser.columns.each do |name, options|
        case options[:agg_function]
        when :sum       then @data[name] = 0
        when :average   then @data[name] = 0
        when :group     then @data[name] = Counter.new
        end
      end
    end

    def [](name)
      case parser[name][:agg_function]
      when :sum       then @data[name]
      when :average   then @data[name].to_f / size.to_f
      when :group     then @data[name]
      end
    end

    def add(record)
      return unless record.valid?
      raise ParserMismatch unless record.class == parser

      @data[:size] += 1
      parser.columns.each do |name, options|
        case options[:agg_function]
        when :sum       then @data[name] += record[name]
        when :average   then @data[name] += record[name]
        when :group     then @data[name].increment(record[name])
        end
      end
    end
  end
end

logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
logfile = logfiles.first

logfile_iterator = LogfileInterval::Logfile.new(logfile)
logfile_iterator.each_line do |line|
  puts line.class # String
  puts line
end

parser = LineParser::AccessLog
logfile_iterator.each_parsed_line(parser) do |record|
  puts record.class # LineParser::AccessLog
  puts record.ip
  puts record.time
end

set_iterator = LogfileInterval::LogfileSet.new(parser, logfiles)
set_iterator.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
end

interval_builder = LogfileInterval::Interval.new(parser, logfiles)
interval_builder.each_interval do |interval|
  puts interval.start_time
  puts interval.length
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
end
