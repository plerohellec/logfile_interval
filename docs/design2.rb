module LogfileInterval
  class Logfile
  end

  class LogfileSet
  end

  class Interval
  end

  class LineParser
    def initialize(regex, columns)
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

    def convert(val, conversion)
      case options[:conversion]
      when :integer then val.to_i
      else val
      end
    end
  end

  class Record
    def initialize(parser, line)
      @parser = parser
      @data = parser.parse(line)
    end

    def valid_columns
      @parser.columns.keys
    end

    def method_missing(meth, *args)
      if valid_columns.include?(meth) && args.none
        self[meth]
      else
        super
      end
    end
  end
end

logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
logfile = logfiles.first
parser = LineParser.new(/blah/, [ { :name=>:ip , :pos => 1 }, ...])

logfile_iterator = LogfileInterval::Logfile.new(parser, logfile)

logfile_iterator.each_line do |line|
  puts line
end

logfile_iterator.each_parsed_line do |record|
  puts record.ip
  puts record.time
end

interval_builder = LogfileInterval::Interval.new(parser, logfiles)

interval_builder.each_interval do |interval|
  puts interval.start_time
  puts interval.length
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
end
