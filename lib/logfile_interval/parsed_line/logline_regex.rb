module LogfileInterval
  module ParsedLine
    module LoglineRegex
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

    end
  end
end

