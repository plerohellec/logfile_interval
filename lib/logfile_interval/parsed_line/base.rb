module LogfileInterval
  module ParsedLine
    class ConfigurationError  < StandardError; end

    class Base
      attr_reader :data

      extend Parser
      extend LoglineRegex

      def initialize(line)
        @data = self.class.parse(line)
        @valid = @data ? true : false
        @skip = @data ? @data[:skip] : false
        @skip_with_exceptions = @data ? @data[:skip_with_exceptions] : false
      end

      def valid?
        @valid
      end

      def skip?
        @skip
      end

      def skip_with_exceptions?
        @skip_with_exceptions
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
