module LogfileInterval
  module LineParser
    AGGREGATION_FUNCTIONS = [ :sum, :average, :timestamp, :group ]

    class InvalidLine         < StandardError; end
    class ConfigurationError  < StandardError; end

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
          raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?
          raise ConfigurationError, 'A regex must be set' unless regex

          match_data = regex.match(line)
          return nil unless match_data
          return nil unless match_data.size >= columns.size+1

          data = {}
          columns.each do |name, options|
            val = match_data[options[:pos]]
            data[name] = convert(val, options[:conversion])
          end
          data
        end

        def create_record(line)
          record = new(line)
          return record if record.valid?
          return nil
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
        @valid = @data ? true : false
      end

      def valid?
        @valid
      end

      def time
        raise NotImplemented
      end
    end
  end
end



