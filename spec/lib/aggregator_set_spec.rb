require 'spec_helper'
require File.join(File.dirname(__FILE__), '..', 'support/lib/timing_log')

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe AggregatorSet, 'with empty columns' do
    subject { AggregatorSet.new({}) }

    it { should respond_to :add }
    it { should respond_to :to_hash }
    it { should respond_to :[] }

  end
end
