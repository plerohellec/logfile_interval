require 'spec_helper'

module LogfileInterval
  module Util
    describe Counter do
      it 'behaves like a hash' do
        c = Counter.new
        c[:a] = 1
        c.keys.should == [:a]
        c.values.should == [1]
        c.delete(:a)
        c.keys.should be_empty

        c[:a] = 1
        c[:b] = 2
        c.keys.sort.should == [:a, :b]
      end

      it 'returns 0 when key does not exist' do
        c = Counter.new
        c[:a].should == 0
      end

      describe :increment do
        it 'adds 1 to value for key argument' do
          c = Counter.new
          c[:a] = 1
          c.increment(:a)
          c[:a].should == 2
        end

        it 'creates new key when missing' do
          c = Counter.new
          c.increment(:a)
          c[:a].should == 1
        end
      end

      describe :add do
        it 'adds number to hash value' do
          c = Counter.new
          c[:a] = 1
          c.add(:a, 5)
          c[:a].should == 6
        end

        it 'creates a new key when missing' do
          c = Counter.new
          c.add(:a, 4)
          c[:a].should == 4
        end
      end

      describe :increment_subkey do
        it 'saves values of type Counter' do
          c = Counter.new
          c.increment_subkey(:a, :sub)
          c[:a].should be_a(Counter)
          c[:a][:sub].should == 1
        end

        it 'raises an error when trying to increment an existing integer key' do
          c = Counter.new
          c[:a] = 1
          lambda { c.increment_subkey(:a, :sub) }.should raise_error(RuntimeError)
        end
      end
    end
  end
end