module LogfileInterval
  module LineParser
    AGGREGATION_FUNCTIONS = [ :sum, :average, :timestamp, :count, :delta, :custom ]

    class InvalidLine         < StandardError; end
    class ConfigurationError  < StandardError; end

    class Base
      attr_reader :data

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
          conversion    = options.fetch(:conversion, :string)
          group_by      = options.fetch(:group_by, nil)
          aggregator    = options.fetch(:aggregator)
          if aggregator == :custom
            custom_class = options.fetch(:custom_class) {
              raise ConfigurationError.new(':custom_class must be set for :custom aggregator type')
            }
            custom_options = options.fetch(:custom_options, {})
          end
          unless AGGREGATION_FUNCTIONS.include?(aggregator)
            raise ArgumentError, "aggregator must be one of #{AGGREGATION_FUNCTIONS.join(', ')}"
          end

          name      = name.to_sym
          group_by  = group_by.to_sym unless group_by.nil?

          agg = Aggregator.klass(options)
          columns[name] = { :pos => pos, :aggregator_class => agg, :conversion => conversion }
          columns[name][:group_by] = group_by if group_by
          columns[name][:custom_options] = custom_options if custom_options

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

        def validate_column_options(options)
        end

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

      def [](name)
        @data[name]
      end
    end
  end
end



