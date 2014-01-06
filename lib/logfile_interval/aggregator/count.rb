module LogfileInterval
  module LineParser
    module Aggregator
      class Count < Base
        def add(value, group_by = nil)
          @val.add(key(group_by), 1)
        end
      end
    end
  end
end
