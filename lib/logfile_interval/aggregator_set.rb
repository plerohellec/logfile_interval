module LogfileInterval
  class AggregatorSet
    def initialize(parser_columns)
      @parser_columns = parser_columns
      @aggregators = {}
      parser_columns.each do |name, options|
        next unless klass = options[:aggregator_class]
        @aggregators[name.to_sym] = klass.new(options.fetch(:custom_options, {}))
      end
    end

    def add(record)
      @parser_columns.each do |name, options|
        next unless @aggregators[name]
        next unless options[:noskip] || !record.skip_with_exceptions?

        group_by_value = record[options[:group_by]] if options[:group_by]
        @aggregators[name].add(record[name], group_by_value)
      end
    end

    def [](name)
      raise ArgumentError, "#{name} field does not exist" unless @aggregators.has_key?(name)
      @aggregators[name.to_sym].values
    end

    def to_hash
      @aggregators.inject({}) do |h, pair|
        k = pair[0]
        v = pair[1]
        h[k] = v.values
        h
      end
    end
  end
end
