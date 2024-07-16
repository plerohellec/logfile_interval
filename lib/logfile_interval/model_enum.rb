module LogfileInterval
  class ModelEnum
    def initialize(models, parser)
      @models   = models
      @parser   = parser
    end

    def each_line
      return enum_for(:each) unless block_given?
      @models.each do |line|
        yield line
      end
    end

    def each_parsed_line
      return enum_for(:each_parsed_line) unless block_given?
      each_line do |line|
        record = @parser.create_record(line)
        yield record if record && !record.skip?
      end
    end
    alias_method :each, :each_parsed_line

    def first_parsed_line
      each_parsed_line.first
    end
    alias_method :first, :first_parsed_line
  end
end

