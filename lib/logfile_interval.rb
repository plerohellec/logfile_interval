lib_dir = File.expand_path('..', __FILE__)

require "#{lib_dir}/logfile_interval/version"
require "#{lib_dir}/logfile_interval/interval"
require "#{lib_dir}/logfile_interval/interval_builder"
require "#{lib_dir}/logfile_interval/logfile"
require "#{lib_dir}/logfile_interval/logfile_set"
require "#{lib_dir}/logfile_interval/line_parser/base"
require "#{lib_dir}/logfile_interval/util/counter"
require "#{lib_dir}/logfile_interval/util/file_backward"
require "#{lib_dir}/logfile_interval/aggregator"

module LogfileInterval
end
