lib_dir = File.expand_path('..', __FILE__)

require "#{lib_dir}/aggregator/base"
require "#{lib_dir}/aggregator/sum"
require "#{lib_dir}/aggregator/count"
require "#{lib_dir}/aggregator/average"
require "#{lib_dir}/aggregator/delta"

module LogfileInterval
  module Aggregator
    def self.klass(options)
      case options[:aggregator]
      when :sum               then Sum
      when :average           then Average
      when :count             then Count
      when :delta             then Delta
      when :custom            then options.fetch(:custom_class)
      end
    end
  end
end
