lib_dir = File.expand_path('..', __FILE__)

require "#{lib_dir}/aggregator/base"
require "#{lib_dir}/aggregator/sum"
require "#{lib_dir}/aggregator/count"
require "#{lib_dir}/aggregator/group_and_count"
require "#{lib_dir}/aggregator/average"
require "#{lib_dir}/aggregator/delta"

module LogfileInterval
  module Aggregator
    def self.klass(aggregator)
      case aggregator
      when :sum               then Sum
      when :average           then Average
      when :count             then Count
      when :group_and_count   then GroupAndCount
      when :delta             then Delta
      end
    end
  end
end
