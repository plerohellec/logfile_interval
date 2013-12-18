module LogfileInterval
  module LineParser
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

      class Base
        include Enumerable

        def initialize
          @val = Counter.new
          @size = Counter.new
        end

        def value(group = nil)
          val(key(group))
        end

        def values
          if single_value?
            value
          else
            self.inject({}) { |h, v| h[v[0]] = v[1]; h }
          end
        end

        def add(value, group_by = nil)
          raise NotImplementedError
        end

        private
        def key(group_by = nil)
          group_by ? group_by : :all
        end

        def single_value?
          return true if @val.empty?
          @val.keys.count == 1 && @val.keys.first == :all
        end

        def each
          @val.each_key do |k|
            yield k, val(k)
          end
        end

        def val(k)
          @val[k]
        end

        def average(k)
          @size[k] > 0 ? @val[k].to_f / @size[k].to_f : 0
        end
      end

      class Sum < Base
        def add(value, group_by = nil)
          @val.add(key(group_by), value)
        end
      end

      class Average < Base
        def add(value, group_by = nil)
          @val.add(key(group_by), value)
          @size.increment(key(group_by))
        end

        def val(k)
          average(k)
        end
      end

      class Count < Base
        def add(value, group_by = nil)
          @val.add(key(group_by), 1)
        end
      end

      class GroupAndCount < Base
        def each
          @val.each { |k, v| yield k, v }
        end

        def add(value, group_by)
          raise ArgumentError, 'group_by argument is mandatory for GroupAndCount#add' unless group_by
          @val.increment_subkey(value, key(group_by))
        end
      end

      class Delta < Base
        def initialize
          @previous = Counter.new
          super
        end

        def add(value, group_by = nil)
          if @previous.has_key?(key(group_by))
            @val.add(key(group_by), @previous[key(group_by)] - value)
            @size.increment(key(group_by))
          end
          @previous.set(key(group_by), value)
        end

        def val(k)
          average(k)
        end
      end
    end
  end
end
