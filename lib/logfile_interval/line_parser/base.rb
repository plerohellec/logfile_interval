module LogfileInterval
  module LineParser
    class ConfigurationError  < StandardError; end

    class Base
      attr_reader :data

      extend Parser

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



