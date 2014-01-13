module LogfileInterval
  module LineParser
    AGGREGATION_FUNCTIONS = [ :sum, :average, :timestamp, :count, :delta, :custom ]

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
          validate_column_options(options)
          options = sanitize_column_options(options)

          name = options[:name]
          columns[name] = options

          define_method(name) do
            @data[name]
          end
        end

        def parse(line)
          raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?
          raise ConfigurationError, 'A regex must be set' unless regex

          match_data = regex.match(line)
          return nil unless match_data

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

        def set_column_custom_options(column_name, options)
          raise ArgumentError, "Invalid column name: #{column_name}" unless columns.has_key?(column_name)
          raise ArgumentError, "This column is not custom: #{column_name}" unless columns[column_name].has_key?(:custom_class)
          columns[column_name][:custom_options] = options
        end

        private

        def validate_column_options(options)
          validate_option(options, :name)
          validate_option(options, :pos)
          validate_option(options, :aggregator)
          unless AGGREGATION_FUNCTIONS.include?(options[:aggregator])
            raise ConfigurationError, "aggregator must be one of #{AGGREGATION_FUNCTIONS.join(', ')}"
          end
          if options[:aggregator] == :custom
            validate_option(options, :custom_class, ':custom_class must be set for :custom aggregator type')
          end
        end

        def validate_option(options, key, errmsg = nil)
          raise ConfigurationError, errmsg || "#{key} is a mandatory column option" unless options.has_key?(key)
        end

        def sanitize_column_options(options)
          options[:name]       = options[:name].to_sym
          if options.has_key?(:group_by)
            options[:group_by]   = options[:group_by].to_sym
          end
          options[:conversion] = options.fetch(:conversion, :string)
          if options[:aggregator] == :custom
            options[:custom_options] = options.fetch(:custom_options, {})
          end
          options[:aggregator_class] = Aggregator.klass(options)
          options.delete(:aggregator)
          options
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



