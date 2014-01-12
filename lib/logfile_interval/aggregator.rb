lib_dir = File.expand_path('..', __FILE__)

puts "lib_dir=#{lib_dir}"

require "#{lib_dir}/aggregator/base"
require "#{lib_dir}/aggregator/sum"
require "#{lib_dir}/aggregator/count"
require "#{lib_dir}/aggregator/group_and_count"
require "#{lib_dir}/aggregator/average"
require "#{lib_dir}/aggregator/delta"

module LogfileInterval
  module Aggregator
    def self.klass(options)
      case options[:aggregator]
      when :sum               then Sum
      when :average           then Average
      when :count
        if options[:group_by] && options[:group_by] != options[:name]
          GroupAndCount
        else
          Count
        end
      when :delta             then Delta
      when :custom            then options.fetch(:custom_class)
      end
    end
  end
end
