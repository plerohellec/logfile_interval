module LogfileInterval
  class Logfile
  end

  class LogfileSet
  end

  class Interval
  end

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

interval_builder = LogfileInterval::Interval.new(parser, logfiles)

interval_builder.each_interval do |interval|
  puts interval.start_time
  puts interval.length
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
end
