module LogfileInterval
  module LineParser
    AGGREGATION_FUNCTIONS = [ :increment, :average, :timestamp, :group ]

    class InvalidLine < StandardError; end

    class Base
      class << self
        attr_reader :regex

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
            @data[name]
          end
        end

        def parse(line)
          match_data = regex.match(line)
          raise InvalidLine unless match_data
          raise InvalidLine unless match_data.size >= columns.size+1

          data = {}
          columns.each do |name, options|
            val = match_data[options[:pos]]
            data[name] = convert(val, options[:conversion])
          end
          data
        end

        def create(line)
          self.class.new(line)
        end

        private

        def convert(val, conversion)
          case conversion
          when :integer then val.to_i
          when :float   then val.to_f
          else val
          end
        end
      end

      def initialize(line)
        @data = self.class.parse(line)
      end

      def time
        raise NotImplemented
      end
    end
  end
end



