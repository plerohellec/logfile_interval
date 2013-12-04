require 'spec_helper'

module LogfileInterval
  module LineParser
    module Aggregator
      describe Aggregator do
        it 'finds the aggregator class' do
          Aggregator.klass(:sum).should == Sum
          Aggregator.klass(:average).should == Average
          Aggregator.klass(:group).should == Group
          Aggregator.klass(:delta).should == Delta
        end
      end

      describe Sum do
        it 'sums up values' do
          sum = Sum.new
          sum.add(3)
          sum.add(5)
          sum.value.should == 8
        end
      end

      describe Average do
        it 'averages values' do
          sum = Average.new
          sum.add(3)
          sum.add(5)
          sum.value.should == 4
        end
      end

      describe Delta do
        it 'averages delta values' do
          sum = Delta.new
          sum.add(1.4)
          sum.add(1.1)
          sum.add(1.0)
          sum.value.round(5).should == 0.2
        end
      end

      describe Group do
        it 'groups values and increment counters' do
          g = Group.new
          g.add('200')
          g.add('500')
          g.add('301')
          g.add('200')
          g.value.should be_a(Hash)
          g.value.should include({'200' => 2})
          g.value.should include({'301' => 1})
          g.value.should include({'500' => 1})
        end
      end
    end
  end
end
