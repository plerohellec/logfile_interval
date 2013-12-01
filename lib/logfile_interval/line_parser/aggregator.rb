module LogfileInterval
  module LineParser
    module Aggregator
      def self.klass(agg_function)
        case agg_function
        when :sum     then Sum
        when :average then Average
        when :group   then Group
        end
      end

      class Sum
        def initialize
          @val = 0
        end

        def add(value)
          @val += value
        end

        def value
          @val
        end
      end

      class Average
        def initialize
          @val  = 0
          @size = 0
        end

        def add(value)
          @val += value
          @size += 1
        end

        def value
          @val.to_f / @size.to_f
        end
      end

      class Group
        def initialize
          @val = Counter.new
        end

        def add(value)
          @val.increment(value)
        end

        def value
          @val
        end
      end
    end
  end
end
