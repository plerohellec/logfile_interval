module LogfileInterval
  module LineParser
    module Aggregator
      def self.klass(agg_function)
        case agg_function
        when :sum     then Sum
        when :average then Average
        when :group   then Group
        when :delta   then Delta
        end
      end

      class Base
        def key(group_by = nil)
          group_by ? group_by : :all
        end
      end

      class Sum < Base
        def initialize
          @val = Counter.new
        end

        def add(value, group_by = nil)
          @val.add(key(group_by), value)
        end

        def value(group = nil)
          @val[key(group)]
        end
      end

      class Average < Base
        def initialize
          @val  = Counter.new
          @size = Counter.new
        end

        def add(value, group_by = nil)
          @val.add(key(group_by), value)
          @size.increment(key(group_by))
        end

        def value(group = nil)
          if @size[key(group)] > 0
            @val[key(group)].to_f / @size[key(group)].to_f
          else
            0
          end
        end
      end

      class Group < Base
        def initialize
          @val = Counter.new
        end

        def add(value, group_by = nil)
          @val.increment(value)
        end

        def value
          @val
        end
      end

      class Delta < Base
        def initialize
          @val = Counter.new
          @size = Counter.new
        end

        def add(value, group_by = nil)
          if @previous
            @val.add(key(group_by), @previous - value)
            @size.increment(key(group_by))
          end
          @previous = value
        end

        def value(group = nil)
          if @size[key(group)] > 0
            @val[key(group)].to_f / @size[key(group)].to_f
          else
            0
          end
        end
      end
    end
  end
end
