# LogfileInterval

Logfile parser and aggregator.

It iterates over each line of logfiles, parses each line and aggregates all lines in a time interval into a single
record made up of the sum, the average, the number of occurences per value or average of the deltas between lines.

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

      add_column :name => 'ip',           :pos => 1, :agg_function => :group
      add_column :name => 'timestamp',    :pos => 2, :agg_function => :timestamp
      add_column :name => 'code',         :pos => 4, :agg_function => :group
      add_column :name => 'length',       :pos => 5, :agg_function => :average,   :conversion => :integer,
      add_column :name => 'length_by_ip', :pos => 5, :agg_function => :average,   :conversion => :integer, :group_by => 'ip'

      def time
        Time.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z')
      end
    end
  end
end
```
The parser must define:
* A regex that extracts the fields out of each line.
* A set of columns that will to be parsed and aggregated in time intervals.
* A 'time' method that converts the mandatory timestamp field of a line into a Time object.

Attributes of a column:
* name: a parsed record will have a method with that name returning the value found at that position
* pos:  the position of the captured field in the regex matched data
* agg_function : the aggregation mode for this field
 * timestamp: the timestamp field will be used to determine to which interval the line belongs, each line MUST have a timestamp
 * group: the aggregator will count the number of occurence of each value of this field
 * average: the aggregator will calculate the average value of this field
 * sum: the aggregator will add up the values of this field
 * delta: the aggregator will caclculate the difference between each line and the next and will average all the deltas
* conversion: the parser will convert the field to an interger or a float when building the parsed record
* group_by: group_by value is the name of another field. The aggregator will apply the agg_function to this field for each distinct value found in the other field.

### Iterate through lines of a single file
And get a parsed record for each line.
```ruby
logfile = 'access.log'
parser = LineParser::AccessLog

log = LogfileInterval::Logfile.new(logfile, parser)
log.each_line do |line|
  puts line.class # String
  puts line
end

parser = LineParser::AccessLog
log.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
  puts record.ip
  puts record.time
  puts record.code
  puts record.length
end
```
**Note**: the Logfile iterators always start with the last line in the file and works its way backward.

### Iterate through lines of multiples files
And get a parsed record for each line.
```ruby
logfiles = [ 'access.log', 'access.log.1', 'access.log.2' ]
set = LogfileInterval::LogfileSet.new(logfiles, parser)
set.each_parsed_line do |record|
  puts record.class # LineParser::AccessLog
end
```
**Note**: the LogfileSet iterators always starts with the most recent file.

### Aggregate lines into intervals
```ruby
length = 5.minutes
interval_builder = LogfileInterval::IntervalBuilder.new(logfiles, length)
interval_builder.each_interval do |interval|
  puts interval.class  # LogfileInterval::Interval
  puts interval.start_time
  puts interval[:length]
  interval[:ip].each do |ip, count|
    puts "#{ip}, #{count}"
  end
  interval[:length_by_ip].each do |ip, avg_length|
    puts "#{ip}, #{avg_length}"
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
