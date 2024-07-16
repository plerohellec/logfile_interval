module LogfileInterval
  module ParsedLine
    module LogfileLine
      attr_reader :regex

      def set_regex(regex)
        @regex = regex
      end

      def parse(line)
        raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?
        raise ConfigurationError, 'A regex must be set' unless @regex

        match_data = @regex.match(line)
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

    end
  end
end

