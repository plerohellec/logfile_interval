module LogfileInterval
  module ParsedLine
    module ModelLine

      def parse(line)
        raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?

        data = { skip: false }
        columns.each do |name, options|
          val = line[options[:colname]]
          data[name] = convert(val, options[:conversion])
        end

        skip_columns.each do |options|
          val = line[options[:colname]]
          if val =~ options[:regex]
            data[:skip] = true
            break
          end
        end

        skip_columns_with_exceptions.each do |options|
          val = line[options[:colname]]
          if val =~ options[:regex]
            data[:skip_with_exceptions] = true
            break
          end
        end

        data
      end

      def skip(options)
        unless options[:colname] && options[:regex]
          raise ConfigurationError, "skip option must include colname and regex"
        end

        skip_columns << { colname: options[:colname], regex: options[:regex] }
      end

      def skip_with_exceptions(options)
        unless options[:colname] && options[:regex]
          raise ConfigurationError, "skip option must include colname and regex"
        end

        skip_columns_with_exceptions << { colname: options[:colname], regex: options[:regex] }
      end

      def validate_column_options(options)
        validate_option(options, :name)
        validate_option(options, :colname)
        validate_option(options, :aggregator)
        if options[:name].to_s == 'skip'
          raise ConfigurationError, "'skip' is a reserved column name"
        end
        unless Aggregator::Base.exist?(options[:aggregator]) || options[:aggregator] == :timestamp
          raise ConfigurationError, "aggregator must be one of #{Aggregator::Base.all.join(', ')}"
        end
      end

    end
  end
end

