module LogfileInterval
  module ParsedLine
    class ConfigurationError  < StandardError; end

    class Base
      attr_reader :data

      extend Parser

      def initialize(line)
        @data = self.class.parse(line)
        @valid = @data ? true : false
        @skip = @data ? @data[:skip] : false
      end

      def valid?
        @valid
      end

      def skip?
        @skip
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
