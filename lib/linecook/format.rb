require 'strscan'

module Linecook
  class Format
    attr_accessor :eol
    attr_accessor :indent_str
    attr_accessor :indent_level
    attr_accessor :tab
    attr_accessor :rstrip
    attr_accessor :lstrip
    attr_accessor :linebreak
    attr_accessor :linebreak_regexp
    attr_reader   :logger

    def initialize(logger=nil)
      @eol = nil
      @indent_str = "  "
      @indent_level = 0
      @rstrip = false
      @lstrip = false
      @tab = nil
      @linebreak = "\n"
      @linebreak_regexp = /\r?\n/
      @logger = logger
    end

    def indent
      @indent_str * @indent_level
    end

    def indent=(str)
      @indent_str = str
      @indent_level = 1
    end

    def strip=(value)
      self.lstrip = value
      self.rstrip = value
    end

    def split(str, lines=[])
      if logger
        logger.debug "split: #{str.inspect}"
      end

      scanner = StringScanner.new(str)

      while line = scanner.scan_until(linebreak_regexp)
        lines << line
      end

      unless scanner.eos?
        lines << scanner.rest
      end

      lines
    end

    def splitln(str, lines=[])
      if logger
        logger.debug "splitln: #{str.inspect}"
      end

      split "#{str}#{linebreak}", lines
    end

    def render(line)
      if logger
        logger.debug "render: #{line.inspect}"
      end

      if line.nil?
        return nil 
      end

      # remove linebreak before processing and determine the line end
      endofline = nil
      if match = linebreak_regexp.match(line)
        line = match.pre_match
        endofline = eol || match[0]
      end

      # now process
      line = line.rstrip if rstrip
      line = line.lstrip if lstrip
      line = "#{indent}#{line}#{endofline}"
      line = line.tr("\t", tab) if tab

      line
    end

    def complete?(line)
      linebreak_regexp.match(line) != nil
    end
  end
end