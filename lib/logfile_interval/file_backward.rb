module LogfileInterval
  # Based on Perl's File::ReadBackwards module, by Uri Guttman.
  class FileBackward
    MAX_READ_SIZE = 1 << 10 # 1024

    def initialize( *args )
      return unless File.exist?(args[0])
      @file = File.new(*args)
      @file.seek(0, IO::SEEK_END)

      @current_pos = @file.pos

      @read_size = @file.pos % MAX_READ_SIZE
      @read_size = MAX_READ_SIZE if @read_size.zero?

      @line_buffer = Array.new
    end

    def gets( sep_string = $/ )
      return nil unless @file
      return @line_buffer.pop if @line_buffer.size > 2 or @current_pos.zero?

      @current_pos -= @read_size
      @file.seek(@current_pos, IO::SEEK_SET)

      @line_buffer[0] = "#{@file.read(@read_size)}#{@line_buffer[0]}"
      @read_size = MAX_READ_SIZE # Set a size for the next read.

      @line_buffer[0] =
      @line_buffer[0].scan(/.*?#{Regexp.escape(sep_string)}|.+/)
      @line_buffer.flatten!

      gets(sep_string)
    end

    def close
      return unless @file
      @file.close()
    end
  end
end

# f = FileBackward.new('../log/development.log')
# i = 0
# while(line = f.gets())
#     puts line
#     i += 1
#     break if i>30
# end
