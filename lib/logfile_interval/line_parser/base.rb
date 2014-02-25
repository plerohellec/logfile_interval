module LogfileInterval
  module LineParser
    class ConfigurationError  < StandardError; end

    class Base
      attr_reader :data

      class << self
        attr_reader :regex, :columns

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
          columns[column_name][:custom_options] = options
        end


        def each(&block)
          columns.each(&block)
        end

        private

        def validate_column_options(options)
          validate_option(options, :name)
          validate_option(options, :pos)
          validate_option(options, :aggregator)
          unless Aggregator::Base.exist?(options[:aggregator]) || options[:aggregator] == :timestamp
            raise ConfigurationError, "aggregator must be one of #{Aggregator::Base.all.join(', ')}"
          end
        end

        def validate_option(options, key, errmsg = nil)
          raise ConfigurationError, errmsg || "#{key} is a mandatory column option" unless options.has_key?(key)
        end

        def sanitize_column_options(options)
          options[:name]       = options[:name].to_sym
          if options.has_key?(:group_by)
            if options[:group_by].to_sym != options[:name]
              options[:group_by] = options[:group_by].to_sym
            else
              options.delete(:group_by)
            end
          end
          options[:conversion] = options.fetch(:conversion, :string)
          options[:aggregator_class] = Aggregator::Base.klass(options[:aggregator])
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



