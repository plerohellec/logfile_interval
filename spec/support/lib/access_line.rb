module LogfileInterval
  # Parser for access.log file line.
  # Example line:
  # 74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"

  class AccessLine

    attr_reader :ip, :timestamp, :url, :code, :length, :referer, :ua, :ext

    def initialize(line)
      @line = line
    end

    def parse
      if(@line =~ /^([\d\.]+)\s+\S+\s+\S+\s+\[(\d\d.*\d\d)\]\s+"(?:GET|POST|PUT|HEAD|DELETE)\s+(\S+)\s+HTTP\S+"\s+(\d+)\s+(\d+)\s+"([^"]*)"\s+"([^"]+)"$/)
        @ip        = $1
        @timestamp = Time.strptime($2, '%d/%b/%Y:%H:%M:%S %z')
        @url       = $3
        @code      = $4.to_i
        @length    = $5.to_i
        @referer   = $6
        @ua        = $7
      else
        return nil
      end
      
      if(@url =~ /[^\.]+\.(\w+)\??\w*$/)
        @ext = $1
      else
        @ext = 'html'
      end
      
      self
    end
  end
end
