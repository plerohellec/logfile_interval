# LogfileInterval

Logfile parser and aggregator

## Installation

Add this line to your application's Gemfile:

    gem 'logfile_interval'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install logfile_interval

## Usage

### Write a LineParser class
```ruby
module LogfileInterval
  module LineParser
    class AccessLog < Base
      # Example line:
      # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 Chrome/25.0.1364.160"

      set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/

      add_column :name => 'ip',        :pos => 1, :agg_function => :group
      add_column :name => 'timestamp', :pos => 2, :agg_function => :timestamp
      add_column :name => 'code',      :pos => 4, :agg_function => :group
      add_column :name => 'length',    :pos => 5, :agg_function => :average,   :conversion => :integer

      def time
        Time.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z')
      end
    end
  end
end
```

### Iterate through lines of a single file
And get a parsed record for each line.
```ruby
logfile = 'access.log'
parser = LineParser::AccessLog

logfile_iterator = LogfileInterval::Logfile.new(logfile, parser)
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
```

### Iterate through lins of multiples files
And get a parsed record for each line.
```ruby
logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
set_iterator = LogfileInterval::LogfileSet.new(logfiles, parser)
set_iterator.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
end
```
### Aggregate lines into intervals
```ruby
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
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
