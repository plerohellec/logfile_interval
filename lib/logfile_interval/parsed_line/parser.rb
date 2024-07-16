module LogfileInterval
  module ParsedLine
    class ConfigurationError  < StandardError; end

    module Parser
      def columns
        @columns ||= {}
      end

      def skip_columns
        @skip_columns ||= []
      end

      def skip_columns_with_exceptions
        @skip_columns_with_exceptions ||= []
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
  end
end
