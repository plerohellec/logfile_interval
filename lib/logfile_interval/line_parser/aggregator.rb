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
          if @size > 0
            @val.to_f / @size.to_f
          else
            0
          end
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

      class Delta
        def initialize
          @val = 0
          @size = 0
        end

        def add(value)
          if @previous
            @val += @previous - value
            @size += 1
          end
          @previous = value
        end

        def value
          if @size > 0
            @val.to_f / @size.to_f
          else
            0
          end
        end
      end
    end
  end
end
