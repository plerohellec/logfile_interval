module LogfileInterval
  module ParsedLine
    module Model

      def parse(line)
        raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?

        data = { skip: false }
        columns.each do |name, options|
          val = line[name]
          data[name] = convert(val, options[:conversion])
        end

        skip_columns.each do |options|
          val = line[name]
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

