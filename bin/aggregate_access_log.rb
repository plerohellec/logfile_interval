#!/usr/bin/env ruby

require 'pp'
require 'date'
require File.join(File.expand_path('../../lib', __FILE__), 'logfile_interval')

logfile = ARGV[0]
unless File.exist?(String(logfile))
  puts "#{logfile} does not exist."
  exit 1
end

class AccessLogParsedLine < LogfileInterval::ParsedLine::Base
  # Example line:
  # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

  set_line_parser :logline_regex

  set_regex /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/

  add_column :name => 'ip',           :pos => 1, :aggregator => :count
  add_column :name => 'timestamp',    :pos => 2, :aggregator => :timestamp
  add_column :name => 'code_by_ip',   :pos => 4, :aggregator => :count,     :group_by => :ip
  add_column :name => 'length',       :pos => 5, :aggregator => :average,                     :conversion => :integer
  add_column :name => 'length_by_ip', :pos => 5, :aggregator => :average,   :group_by => :ip, :conversion => :integer
  add_column :name => 'referer',      :pos => 6, :aggregator => :count
  add_column :name => 'referer_by_ip', :pos => 6, :aggregator => :count,    :group_by => :ip

  def time
    DateTime.strptime(self.timestamp, '%d/%b/%Y:%H:%M:%S %z').to_time
  end
end

file = LogfileInterval::Logfile.new(logfile, AccessLogParsedLine)
builder = LogfileInterval::IntervalBuilder.new(file.each_parsed_line, AccessLogParsedLine, 300)
builder.each_interval do |interval|
  next unless interval.size > 0

  puts
  puts "start_time=#{interval.start_time} size=#{interval.size}"
  pp interval[:ip]
  pp interval[:referer_by_ip]
  STDIN.gets
end
