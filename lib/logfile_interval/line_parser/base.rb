module LogfileInterval
  module LineParser
    AGGREGATION_FUNCTIONS = [ :increment, :average, :timestamp, :group ]

    class InvalidLine < StandardError; end

    class Base
      class << self
        attr_reader :regex, :columns

        def columns
          @columns ||= {}
        end

        def set_regex(regex)
          @regex = regex
        end

        def add_column(options)
          name          = options.fetch(:name)
          pos           = options.fetch(:pos)
          agg_function  = options.fetch(:agg_function)
          conversion    = options.fetch(:conversion, :string)
          unless AGGREGATION_FUNCTIONS.include?(agg_function)
            raise ArgumentError, "agg_function must be one of #{AGGREGATION_FUNCTIONS.join(', ')}"
          end

          columns[name] = { :pos => pos, :agg_function => agg_function, :conversion => conversion }

          define_method(name) do
            case self.class.columns[name][:conversion]
            when :integer then @data[name].to_i
            when :float   then @data[name].to_f
            else @data[name]
            end
          end
        end

        def parse(line)
          regex.match(line)
        end
      end

      def initialize(line)
        @data = {}

        match_data = self.class.parse(line)
        raise InvalidLine unless match_data
        raise InvalidLine unless match_data.size >= self.class.columns.size+1

        self.class.columns.each do |name, options|
          @data[name] = match_data[options[:pos]]
        end
      end

      def time
        raise NotImplemented
      end
    end
  end
end



