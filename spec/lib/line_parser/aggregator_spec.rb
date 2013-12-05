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

      shared_examples 'an aggregator' do
        let(:aggregator) { described_class.new }

        [ :add, :value, :values ].each do |method|
          it "responds to #{method}" do
            aggregator.should respond_to(method)
          end
        end

        context 'values' do
          context 'with one group' do
            before :each do
              aggregator.add(5, :key1)
            end

            it 'returns a hash' do
              aggregator.values.should be_a(Hash) unless aggregator.is_a?(Delta)
            end
          end

          context 'with several groups' do
            before :each do
              aggregator.add(5, :key1)
              aggregator.add(3, :key2)
              aggregator.add(3, :key1)
            end

            it 'returns a hash' do
              aggregator.values.should be_a(Hash)
            end
          end

          context 'with no group' do
            before :each do
              aggregator.add(5)
              aggregator.add(3)
            end

            it 'returns a numeric' do
              aggregator.values.should be_a(Numeric) unless aggregator.is_a?(Group)
            end
          end
        end
      end

      [ Group, Sum, Average, Delta ]. each do |klass|
        describe klass do
          it_behaves_like 'an aggregator'
        end
      end


      describe 'without group_by key' do
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
            avg = Average.new
            avg.add(3)
            avg.add(5)
            avg.value.should == 4
          end
        end

        describe Delta do
          it 'averages delta values' do
            d = Delta.new
            d.add(1.4)
            d.add(1.1)
            d.add(1.0)
            d.value.round(5).should == 0.2
          end
        end

        describe Group do
          it 'groups values and increment counters' do
            g = Group.new
            g.add('200')
            g.add('500')
            g.add('301')
            g.add('200')
            g.values.should be_a(Hash)
            g.values.should include({'200' => 2})
            g.values.should include({'301' => 1})
            g.values.should include({'500' => 1})
          end
        end
      end

      describe 'with group_by key' do

        describe Sum do
          it 'sums up values by key' do
            sum = Sum.new
            sum.add(3, :key1)
            sum.add(5, :key2)
            sum.add(5, :key1)
            sum.values.should be_a(Hash)
            sum.values.size.should == 2
            sum.value(:key1).should == 8
            sum.values[:key1].should == 8
            sum.value(:key2).should == 5
            sum.values[:key2].should == 5
          end
        end


        describe Average do
          it 'averages values by key' do
            sum = Average.new
            sum.add(3, :key1)
            sum.add(5, :key2)
            sum.add(5, :key1)
            sum.values.should be_a(Hash)
            sum.values.size.should == 2
            sum.value(:key1).should == 4
            sum.values[:key1].should == 4
            sum.value(:key2).should == 5
            sum.values[:key2].should == 5
          end
        end

        describe Group do
        end

        describe Delta do
          it 'averages deltas by key' do
            d = Delta.new
            d.add(9, :key1)
            d.add(10, :key2)
            d.add(5, :key1)
            d.add(8, :key2)
            d.add(3, :key1)
            d.add(5, :key2)
            d.values.should be_a(Hash)
            d.values.size.should == 2
            d.value(:key1).should == 3
            d.values[:key1].should == 3
            d.value(:key2).should == 2.5
            d.values[:key2].should == 2.5
          end
        end

      end
    end
  end
end
