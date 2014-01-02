# LogfileInterval [![Build Status](https://travis-ci.org/plerohellec/logfile_interval.png?branch=master)](https://travis-ci.org/plerohellec/logfile_interval)

Logfile parser and aggregator.

It iterates over 1 or more logfiles, parses each line and aggregates them into time intervals. Each interval object
includes aggregated data for each field of the logfile.

Aggregated data can be for example the sum, the average value or the number of occurences of each value.

## Example
This example will parse an access.log file and aggregate the data into 5 minute intervals.

In each interval, it counts
* the number of requests per IP address
* the number of requests for each HTTP status code
* the number of requests for each HTTP status code and IP address.

Full script is in [readme.rb](bin/readme.rb).
### Code
```ruby
require 'pp'
require 'date'
require 'logfile_interval'

class AccessLog < LogfileInterval::LineParser::Base
  # Example line:
  # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 Chrome/25.0.1364.160"

  set_regex /^([\d\.]+)\s+.*\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+/

  add_column :name => 'ip',           :pos => 1, :aggregator => :count,     :group_by => 'ip'
  add_column :name => 'timestamp',    :pos => 2, :aggregator => :timestamp
  add_column :name => 'code',         :pos => 4, :aggregator => :count,     :group_by => 'code'
  add_column :name => 'code_by_ip',   :pos => 4, :aggregator => :count,     :group_by => 'ip'

  def time
    DateTime.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z').to_time
  end
end

path = ENV['ACCESS_LOG_PATH']
file = LogfileInterval::Logfile.new(path, AccessLog)
unless file.exist?
  puts "#{path} is not found"
  exit 1
end

builder = LogfileInterval::IntervalBuilder.new(file, 300)
builder.each_interval do |interval|
  next unless interval.size > 0

  puts
  puts "start time of interval:               #{interval.start_time}"
  puts "number of seconds in interval:        #{interval.length}"
  puts "number of requests found in interval: #{interval.size}"
  puts "number of requests per ip address in interval:"
  pp interval[:ip]
  puts "number of requests per http code in interval:"
  pp interval[:code]
  puts "for each http code, number of requests grouped by ip:"
  pp interval[:code_by_ip]
end
```
### Output
Logfile used for example: [access.log](spec/support/logfiles/access.log.3).
```
start time of interval:            2012-01-01 16:30:00 -0800
number of seconds in interval:     300
number of requests found in interval: 4
number of requests per ip address in interval:
{"78.54.172.146"=>3, "66.249.68.148"=>1}
number of requests per http code in interval:
{"200"=>3, "302"=>1}
for each ip, number of requests grouped by http code:
{"200"=>{"78.54.172.146"=>2, "66.249.68.148"=>1}, "302"=>{"78.54.172.146"=>1}}

start time of interval:            2012-01-01 16:25:00 -0800
number of seconds in interval:     300
number of requests found in interval: 3
number of requests per ip address in interval:
{"78.54.172.146"=>1, "173.192.238.51"=>1, "66.249.67.176"=>1}
number of requests per http code in interval:
{"200"=>1, "301"=>2}
for each ip, number of requests grouped by http code:
{"200"=>{"78.54.172.146"=>1}, "301"=>{"173.192.238.51"=>1, "66.249.67.176"=>1}}
```

## Usage
### Write a LineParser class
The first step is to define a LineParser class as in the example above. The parser lists the fields that must be parsed, how a timestamp can be extracted from each line and how to aggregate values into intervals.
```ruby
module LogfileInterval
  module LineParser
    class AccessLog < Base
      # Example line:
      # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 Chrome/25.0.1364.160"

      set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/

      add_column :name => 'ip',           :pos => 1, :aggregator => :count,     :group_by => 'ip'
      add_column :name => 'timestamp',    :pos => 2, :aggregator => :timestamp
      add_column :name => 'code',         :pos => 4, :aggregator => :count,     :group_by => 'code'
      add_column :name => 'code_by_ip',   :pos => 4, :aggregator => :count,     :group_by => 'ip'
      add_column :name => 'length',       :pos => 5, :aggregator => :average,                      :conversion => :integer
      add_column :name => 'length_by_ip', :pos => 5, :aggregator => :average,   :group_by => 'ip', :conversion => :integer

      def time
        Time.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z')
      end
    end
  end
end
```
#### The parser must define:
* A regex that extracts the fields out of each line.
* A set of columns that will to be parsed and aggregated in time intervals.
* A 'time' method that converts the mandatory timestamp field of a line into a Time object.

#### Attributes of a column:
* name: a parsed record will have a method with that name returning the value found at that position
* pos:  the position of the captured field in the regex matched data
* aggregator : the aggregation mode for this field
* conversion: the parser will convert the field to an integer or a float when building the parsed record
* group_by: group_by value is the name of another field. Values will be aggregated for each 'name', 'group_by' pair.

#### Aggregator types and options
* timestamp: the timestamp field will be used to determine to which interval the line belongs, each line MUST have a timestamp
* count: the aggregator will count the number of occurence of this field
  * without the group_by option, it will just count the total number of lines (probably useless)
  * with a group_by option pointing to the same field as the current one, it will count the number of occurence
    per distinct value of this column
  * with a group_by option pointing to another field, it will count the number of occurences of (this field, other field) pairs.
* average: the aggregator will calculate the average value of this field
* sum: the aggregator will add up the values of this field
* delta: the aggregator will caclculate the difference between each line and the next and will average all the deltas

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
interval_builder = LogfileInterval::IntervalBuilder.new(set, length)
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

## Installation
Add this line to your application's Gemfile:

    gem 'logfile_interval'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install logfile_interval

## Contributing
1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
