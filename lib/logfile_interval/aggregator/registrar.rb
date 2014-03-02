module LogfileInterval
  module Aggregator
    module Registrar
      def inherited(subclass)
        name = subclass.to_s
        name = $1 if name =~ /(\w+)$/
        name = name.scan(/[A-Z][a-z]*/).join("_").downcase.to_sym
        aggregator_classes[name] = subclass
      end

      def aggregator_classes
        @@aggregator_classes ||= {}
      end

      def register_aggregator(name, klass)
        puts "register #{klass}"
        aggregator_classes[name] = klass
      end

      def klass(name)
        aggregator_classes[name]
      end

      def exist?(name)
        aggregator_classes.include?(name)
      end

      def all
        aggregator_classes.keys
      end
    end
  end
end
