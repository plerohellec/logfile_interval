require 'spec_helper'

module LogfileInterval
  data_dir = File.join(File.dirname(__FILE__), '..', 'support/logfiles')

  describe 'AccessLine' do
    it 'parses a line' do
      line = '74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /ppa/google_chrome HTTP/1.1" 200 7855 "https://www.google.com/" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"'
      al = AccessLine.new(line)
      al = al.parse
      al.should_not be_nil
      
      al.timestamp.should == Time.new(2013, 03, 31, 06, 54, 12, '-07:00')
      al.url.should == '/ppa/google_chrome'
      al.referer.should == 'https://www.google.com/'
      al.ip.should == '74.75.19.145'
      al.ua.should == "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22"
      al.code.should == 200
      al.length.should == 7855
    end

    it 'does not barf of malformed line' do
      line = '1365975896 PostsController#index    total=546 view=252.7 db=63.0 ip=127.0.0.1'
      al = AccessLine.new(line)
      expect { al.parse }.to_not raise_error
      al.timestamp.should be_nil
    end
    
    it 'finds file extension in request url' do
      line = '74.75.19.145 - - [31/Mar/2013:06:54:12 -0700] "GET /images/logo.gif HTTP/1.1" 200 7855 "" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22"' 
      
      al = AccessLine.new(line)
      al = al.parse
      al.should_not be_nil
      
      al.ext.should == 'gif'
      al.ua.should match /AppleWebKit/
    end
  end

  describe 'Access Logfile' do
    before :each do
      @alf = Logfile.new(AccessLine, "#{data_dir}/access.log")
    end
    
    it 'first_timestamp returns time of first line in file' do
      @alf = Logfile.new(AccessLine, "#{data_dir}/access.log")
      #01/Jan/2012:00:57:47 -0800
      @alf.first_timestamp.should == Time.new(2012, 01, 01, 00, 57, 47, '-08:00')
    end
      
    it 'each_line should enumerate each line backwards' do
      lines = []
      @alf.each_line do |line|
        lines << AccessLine.new(line).parse
      end
      lines.first.timestamp.should == Time.new(2012, 01, 01, 16, 30, 51, '-08:00')
      lines.first.code.should == 200
      lines.last.timestamp.should  == Time.new(2012, 01, 01, 00, 57, 47, '-08:00')
      lines.last.code.should == 301
    end
  end
end

