require 'json'

module LogfileInterval
  module ParsedLine
    class Json < Base
      # ParsedLine subclass for JSON-format log lines.
      #
      # Instead of set_regex, columns are mapped by JSON key:
      #
      #   class ApiLog < LogfileInterval::ParsedLine::Json
      #     add_column :name => 'timestamp',    :key => 'ts',  :aggregator => :timestamp
      #     add_column :name => 'ip',           :key => 'client_ip',  :aggregator => :count
      #     add_column :name => 'duration',     :key => 'response_time', :aggregator => :average, :conversion => :integer
      #
      #     skip :key => 'user_agent', :regex => /bot/
      #
      #     def time
      #       Time.parse(self.timestamp)
      #     end
      #   end
      #
      # If :key is omitted, the column name is used as the JSON key.

      def self.parse(line)
        raise ConfigurationError, 'There must be at least 1 configured column' unless columns.any?

        parsed = begin
          JSON.parse(line)
        rescue JSON::ParserError
          return nil
        end

        data = { skip: false }
        columns.each do |name, options|
          key = options[:key] || options[:name].to_s
          val = parsed[key]
          data[name] = convert(val, options[:conversion])
        end

        skip_columns.each do |options|
          key = options[:key] || options[:name].to_s
          val = parsed[key]
          if val.to_s =~ options[:regex]
            data[:skip] = true
            break
          end
        end

        skip_columns_with_exceptions.each do |options|
          key = options[:key] || options[:name].to_s
          val = parsed[key]
          if val.to_s =~ options[:regex]
            data[:skip_with_exceptions] = true
            break
          end
        end

        data
      end
    end
  end
end
