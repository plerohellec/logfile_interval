require 'spec_helper'

module LogfileInterval

  module Aggregator
    class CustomAggregator; end
      
    describe Aggregator do
      it 'finds the aggregator class' do
        Aggregator.klass({ :aggregator => :sum}).should == Sum
        Aggregator.klass({ :aggregator => :average}).should == Average
        Aggregator.klass({ :aggregator => :count}).should == Count
        Aggregator.klass({ :aggregator => :count, :group_by => :foo}).should == GroupAndCount
        Aggregator.klass({ :aggregator => :delta}).should == Delta
        Aggregator.klass({ :aggregator => :custom, :custom_class => CustomAggregator}).should == CustomAggregator
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
            aggregator.values.should be_a(Numeric) unless aggregator.is_a?(Count)
          end
        end
      end
    end

    [ Count, Sum, Average, Delta ]. each do |klass|
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

      describe Count do
        it 'groups values and increment counters' do
          g = Count.new
          g.add('200')
          g.add('500')
          g.add('301')
          g.add('200')
          g.value.should == 4
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
          avg = Average.new
          avg.add(3, :key1)
          avg.add(5, :key2)
          avg.add(5, :key1)
          avg.values.should be_a(Hash)
          avg.values.size.should == 2
          avg.value(:key1).should == 4
          avg.values[:key1].should == 4
          avg.value(:key2).should == 5
          avg.values[:key2].should == 5
        end
      end

      describe Count do
        it 'groups values and increment counters' do
          g = Count.new
          g.add('200', '200')
          g.add('500', '500')
          g.add('301', '301')
          g.add('200', '200')
          g.values.should be_a(Hash)
          g.values.should include({'200' => 2})
          g.values.should include({'301' => 1})
          g.values.should include({'500' => 1})
        end
      end

      describe GroupAndCount do
        it 'each yields a key and a hash' do
          gac = GroupAndCount.new
          gac.add :key1, :subkey1
          gac.first.should be_an(Array)
          gac.first.size.should == 2
          gac.first[1].should be_a(Hash)
        end

        context :add do
          before :each do
            @gac = GroupAndCount.new
          end

          it 'requires a group_by argument' do
            lambda { @gac.add('foo') }.should raise_error ArgumentError
          end

          it 'counts number of occurence of subkey for key' do
            @gac.add :key1, :subkey1
            @gac.add :key1, :subkey2
            @gac.add :key2, :subkey1
            @gac.add :key2, :subkey1
            @gac.add :key2, :subkey3

            @gac.values[:key1][:subkey1].should == 1
            @gac.values[:key1][:subkey2].should == 1
            @gac.values[:key2][:subkey1].should == 2
            @gac.values[:key2][:subkey2].should == 0
            @gac.values[:key2][:subkey3].should == 1
          end
        end
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