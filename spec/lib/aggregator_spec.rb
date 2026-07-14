require 'spec_helper'

module LogfileInterval

  module Aggregator
    class CustomAggregator < Base; end

    class BizarroAggregator < Base
      register_aggregator :weird_add, self
    end
      
    describe Base do
      it 'finds the aggregator class' do
        Aggregator::Base.klass(:num_lines).should == NumLines
        Aggregator::Base.klass(:sum).should == Sum
        Aggregator::Base.klass(:average).should == Average
        Aggregator::Base.klass(:count).should == Count
        Aggregator::Base.klass(:delta).should == Delta
        Aggregator::Base.klass(:percentile).should == Percentile
        Aggregator::Base.klass(:custom_aggregator).should == CustomAggregator
        Aggregator::Base.klass(:weird_add).should == BizarroAggregator
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
            aggregator.values.should be_a(Hash) unless [ Delta, NumLines ].include?(aggregator.class)
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

    [ NumLines, Count, Sum, Average, Delta, Percentile ]. each do |klass|
      describe klass do
        it_behaves_like 'an aggregator'
      end
    end


    describe 'without group_by key' do
      describe NumLines do
        it 'counts total number of lines' do
          nl = NumLines.new
          nl.add(55)
          nl.add(54)
          nl.add(1008)
          nl.value.should == 3
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
          avg = Average.new
          avg.add(3)
          avg.add(5)
          avg.value.should == 4
        end
      end

      describe Delta do
        it 'averages delta values' do
          d = Delta.new
          d.add(1.0)
          d.add(1.1)
          d.add(1.4)
          d.value.round(5).should == 0.2
        end
      end

      describe Count do
        it 'without group_by: counts occurrences per distinct value' do
          g = Count.new
          g.add('200')
          g.add('500')
          g.add('301')
          g.add('200')
          g.values.should == { '200' => 2, '500' => 1, '301' => 1 }
        end
      end

      describe Percentile do
        it 'returns the median (p50) by default' do
          p = Percentile.new
          p.add(1)
          p.add(3)
          p.add(5)
          p.value.should == 3
        end

        it 'computes any percentile at query time' do
          p = Percentile.new
          p.add(1)
          p.add(2)
          p.add(3)
          p.add(4)
          p.add(5)
          p.compute_percentile(50).should == 3
          p.compute_percentile(95).should == 4.8
          p.compute_percentile(99).should == 4.96
        end

        it 'returns 0 when no values added' do
          p = Percentile.new
          p.value.should == 0
        end

        it 'returns 0 for compute_percentile on empty set' do
          p = Percentile.new
          p.compute_percentile(95).should == 0
        end

        it 'returns the only value for a single element' do
          p = Percentile.new
          p.add(42)
          p.value.should == 42
        end

        it 'computes percentile with interpolation at the boundary' do
          p = Percentile.new
          p.add(1)
          p.add(2)
          p.add(3)
          p.compute_percentile(100).should == 3
        end

        it 'computes percentile per group' do
          p = Percentile.new
          p.add(10, :a)
          p.add(20, :a)
          p.add(30, :a)
          p.add(100, :b)
          p.add(200, :b)
          p.compute_percentile(50, :a).should == 20
          p.compute_percentile(50, :b).should == 150
          p.compute_percentile(95, :b).should == 195
        end

        it 'returns the median through the AggregatorSet pipeline' do
          cols = {
            :val => { :aggregator_class => Percentile, :custom_options => {} },
          }
          set = AggregatorSet.new(cols)
          rec = double('record', :[] => 100, :skip_with_exceptions? => false)
          set.add(rec)
          rec2 = double('record', :[] => 200, :skip_with_exceptions? => false)
          set.add(rec2)
          rec3 = double('record', :[] => 300, :skip_with_exceptions? => false)
          set.add(rec3)
          set[:val].should == 200
        end
      end
    end

    describe 'with nil values (missing JSON field)' do

      describe NumLines do
        it 'skips nil values and only counts non-nil lines' do
          nl = NumLines.new
          nl.add(nil)
          nl.add(42)
          nl.add(nil)
          nl.value.should == 1
        end
      end

      describe Sum do
        it 'treats nil as 0 in a sum' do
          sum = Sum.new
          sum.add(nil)
          sum.add(3)
          sum.add(nil)
          sum.value.should == 3
        end
      end

      describe Average do
        it 'skips nil values from both sum and count' do
          avg = Average.new
          avg.add(3)
          avg.add(nil)
          avg.add(5)
          avg.value.should == 4
        end

        it 'returns 0 when only nil values are added' do
          avg = Average.new
          avg.add(nil)
          avg.add(nil)
          avg.value.should == 0
        end
      end

      describe Delta do
        it 'skips nil values (does not compute delta, does not update previous)' do
          d = Delta.new
          d.add(10)
          d.add(nil)
          d.add(15)
          d.value.should == 5
        end

        it 'skips trailing nil values' do
          d = Delta.new
          d.add(10)
          d.add(15)
          d.add(nil)
          d.value.should == 5
        end

        it 'returns 0 when only nil values are added' do
          d = Delta.new
          d.add(nil)
          d.add(nil)
          d.value.should == 0
        end
      end

      describe Count do
        it 'ignores nil values' do
          c = Count.new
          c.add('200')
          c.add(nil)
          c.add('200')
          c.add(nil)
          c.value.should == 0
          c.values.should == { '200' => 2 }
        end

        it 'returns empty hash when all values are nil' do
          c = Count.new
          c.add(nil)
          c.add(nil)
          c.values.should == {}
        end

        it 'ignores nil values with group_by' do
          c = Count.new
          c.add(:key1, :group_a)
          c.add(nil, :group_a)
          c.add(:key2, :group_a)
          c.add(nil, :group_b)
          c.values[:key1][:group_a].should == 1
          c.values[:key2][:group_a].should == 1
          c.values[:group_b].should be_nil
        end
      end

      describe Percentile do
        it 'skips nil values in the sorted list' do
          p = Percentile.new
          p.add(10)
          p.add(nil)
          p.add(20)
          p.value.should == 15
        end

        it 'returns 0 when only nil values are added' do
          p = Percentile.new
          p.add(nil)
          p.add(nil)
          p.value.should == 0
        end
      end

      describe FirstValue do
        it 'skips nil and records the first real value' do
          fv = FirstValue.new
          fv.add(nil)
          fv.add(42)
          fv.value.should == 42
        end
      end

      describe LastValue do
        it 'skips nil and records the last real value' do
          lv = LastValue.new
          lv.add(10)
          lv.add(nil)
          lv.add(20)
          lv.value.should == 20
        end
      end

      describe Appender do
        it 'ignores nil values' do
          a = Appender.new
          a.add(nil)
          a.add('a')
          a.add(nil)
          a.value.size.should == 1
          a.value.should include('a')
          a.value.should_not include(nil)
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
        it 'with group_by to another field: counts (value, group_value) pairs' do
          gac = Count.new
          gac.add :key1, :subkey1
          gac.add :key1, :subkey2
          gac.add :key2, :subkey1
          gac.add :key2, :subkey1
          gac.add :key2, :subkey3

          gac.values[:key1][:subkey1].should == 1
          gac.values[:key1][:subkey2].should == 1
          gac.values[:key2][:subkey1].should == 2
          gac.values[:key2][:subkey2].should == 0
          gac.values[:key2][:subkey3].should == 1
        end

        it 'with group_by to the same field: each value maps to itself in a nested hash' do
          gac = Count.new
          gac.add '200', '200'
          gac.add '200', '200'
          gac.add '500', '500'

          gac.values['200']['200'].should == 2
          gac.values['500']['500'].should == 1
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
          d.value(:key1).should == -3
          d.values[:key1].should == -3
          d.value(:key2).should == -2.5
          d.values[:key2].should == -2.5
        end
      end
    end
  end
end
