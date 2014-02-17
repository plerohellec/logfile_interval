#!/usr/bin/env ruby

require 'pp'
require 'date'
require File.join(File.expand_path('../../lib', __FILE__), 'logfile_interval')

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
parsed_line_enum = file.each_parsed_line

builder = LogfileInterval::IntervalBuilder.new(parsed_line_enum, AccessLog, 300)
builder.each_interval do |interval|
  next unless interval.size > 0

  puts
  puts "start time of interval:            #{interval.start_time}"
  puts "number of seconds in interval:     #{interval.length}"
  puts "number of requests found in interval: #{interval.size}"
  puts "number of requests per ip address in interval:"
  pp interval[:ip]
  puts "number of requests per http code in interval:"
  pp interval[:code]
  puts "for each ip, number of requests grouped by http code:"
  pp interval[:code_by_ip]
end
