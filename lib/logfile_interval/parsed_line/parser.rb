module LogfileInterval
  module ParsedLine
    class ConfigurationError  < StandardError; end

    module Parser
      attr_reader :regex

      def columns
        @columns ||= {}
      end

      def skip_columns
        @skip_columns ||= []
      end

      def skip_columns_with_exceptions
        @skip_columns_with_exceptions ||= []
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

      def skip(options)
        unless options[:pos] && options[:regex]
          raise ConfigurationError, "skip option must include pos and regex"
        end

        skip_columns << { pos: options[:pos], regex: options[:regex] }
      end

      def skip_with_exceptions(options)
        unless options[:pos] && options[:regex]
          raise ConfigurationError, "skip option must include pos and regex"
        end

        skip_columns_with_exceptions << { pos: options[:pos], regex: options[:regex] }
      end

      def parse(line)
        raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?
        raise ConfigurationError, 'A regex must be set' unless regex

        match_data = regex.match(line)
        return nil unless match_data

        data = { skip: false }
        columns.each do |name, options|
          val = match_data[options[:pos]]
          data[name] = convert(val, options[:conversion])
        end

        skip_columns.each do |options|
          val = match_data[options[:pos]]
          if val =~ options[:regex]
            data[:skip] = true
            break
          end
        end

        skip_columns_with_exceptions.each do |options|
          val = match_data[options[:pos]]
          if val =~ options[:regex]
            data[:skip_with_exceptions] = true
            break
          end
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
        if options[:name].to_s == 'skip'
          raise ConfigurationError, "'skip' is a reserved column name"
        end
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
  end
end
