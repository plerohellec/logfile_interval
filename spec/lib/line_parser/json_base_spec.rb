require 'spec_helper'

module LogfileInterval
  module ParsedLine

    describe Json do
      # Sample JSON log line
      let(:line) { '{"timestamp":"2024-01-01T16:30:51Z","ip":"78.54.172.146","method":"GET","path":"/api/users","status":200,"duration":42,"user_agent":"Mozilla/5.0"}' }

      # A minimal JSON parser for testing
      let(:parser_class) do
        Class.new(Json) do
          add_column :name => 'timestamp', :aggregator => :timestamp
          add_column :name => 'ip',        :aggregator => :count
          add_column :name => 'status',    :aggregator => :count
          add_column :name => 'duration',  :aggregator => :average, :conversion => :integer

          def time
            Time.parse(self.timestamp)
          end
        end
      end

      describe '#initialize' do
        it 'parses a valid JSON line and extracts fields by key' do
          record = parser_class.create_record(line)
          record.should_not be_nil
          record.timestamp.should == '2024-01-01T16:30:51Z'
          record.ip.should == '78.54.172.146'
          record.status.should == 200
          record.duration.should == 42
        end

        it 'returns nil for invalid JSON' do
          record = parser_class.create_record('not valid json')
          record.should be_nil
        end

        it 'returns nil for empty string' do
          record = parser_class.create_record('')
          record.should be_nil
        end

        it 'handles missing JSON keys gracefully' do
          incomplete_line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"78.54.172.146"}'
          record = parser_class.create_record(incomplete_line)
          record.should_not be_nil
          record.status.should be_nil   # missing key, no conversion => nil
          record.duration.should == 0   # missing key with :integer => nil.to_i => 0
        end

        it 'returns valid? false for invalid JSON' do
          record = parser_class.new('garbage')
          record.valid?.should be false
        end
      end

      describe 'with :key omitted (defaults to column name)' do
        let(:default_key_parser) do
          Class.new(Json) do
            add_column :name => 'timestamp', :aggregator => :timestamp
            add_column :name => 'ip',        :aggregator => :count

            def time
              Time.parse(self.timestamp)
            end
          end
        end

        it 'uses column name as JSON key' do
          line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"78.54.172.146"}'
          record = default_key_parser.create_record(line)
          record.should_not be_nil
          record.timestamp.should == '2024-01-01T16:30:51Z'
          record.ip.should == '78.54.172.146'
        end
      end

      describe 'skip with :key' do
        let(:skipping_parser) do
          Class.new(Json) do
            add_column :name => 'timestamp', :aggregator => :timestamp
            add_column :name => 'ip',        :aggregator => :count

            skip :key => 'user_agent', :regex => /bot/i

            def time
              Time.parse(self.timestamp)
            end
          end
        end

        it 'skips lines where the field matches the skip regex' do
          bot_line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"66.249.68.148","user_agent":"Googlebot/2.1"}'
          record = skipping_parser.new(bot_line)
          record.skip?.should be true
        end

        it 'does not skip lines that do not match' do
          normal_line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"78.54.172.146","user_agent":"Mozilla/5.0"}'
          record = skipping_parser.new(normal_line)
          record.skip?.should be false
        end

        it 'handles missing skip key without error' do
          no_agent_line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"78.54.172.146"}'
          record = skipping_parser.new(no_agent_line)
          record.skip?.should be false
        end
      end

      describe 'type conversion' do
        let(:conversion_parser) do
          Class.new(Json) do
            add_column :name => 'timestamp', :key => 'time',  :aggregator => :timestamp
            add_column :name => 'count',     :key => 'count', :aggregator => :sum, :conversion => :integer
            add_column :name => 'ratio',     :key => 'ratio', :aggregator => :average, :conversion => :float

            def time
              Time.parse(self.timestamp)
            end
          end
        end

        it 'converts to integer' do
          line = '{"time":"2024-01-01T16:30:51Z","count":"42","ratio":"3.14"}'
          record = conversion_parser.create_record(line)
          record.count.should == 42
          record.count.should be_a(Integer)
        end

        it 'converts to float' do
          line = '{"time":"2024-01-01T16:30:51Z","count":"42","ratio":"3.14"}'
          record = conversion_parser.create_record(line)
          record.ratio.should == 3.14
          record.ratio.should be_a(Float)
        end
      end

      describe 'skip_with_exceptions with :key' do
        let(:exception_skip_parser) do
          Class.new(Json) do
            add_column :name => 'timestamp', :aggregator => :timestamp
            add_column :name => 'ip',        :aggregator => :count

            skip_with_exceptions :key => 'path', :regex => %r{^/health}

            def time
              Time.parse(self.timestamp)
            end
          end
        end

        it 'sets skip_with_exceptions flag when field matches' do
          health_line = '{"timestamp":"2024-01-01T16:30:51Z","ip":"127.0.0.1","path":"/health"}'
          record = exception_skip_parser.new(health_line)
          record.skip_with_exceptions?.should be true
        end
      end
    end
  end
end
