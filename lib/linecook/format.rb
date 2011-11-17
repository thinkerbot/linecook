require 'strscan'

module Linecook
  class Format
    attr_accessor :eol
    attr_writer   :indent
    attr_accessor :indent_str
    attr_accessor :indent_level
    attr_accessor :tab
    attr_accessor :rstrip
    attr_accessor :lstrip
    attr_accessor :linebreak
    attr_reader   :logger

    def initialize(logger=nil)
      @eol = "\n"
      @indent = nil
      @indent_str = "  "
      @indent_level = 0
      @rstrip = false
      @lstrip = false
      @tab = nil
      @linebreak = /\r?\n/
      @logger = logger
    end

    def indent
      @indent || @indent_str * @indent_level
    end

    def split(str)
      if logger
        logger.debug "split: #{str.inspect}"
      end

      scanner = StringScanner.new(str)
      lines = []

      while line = scanner.scan_until(linebreak)
        lines << render(line)
      end

      lines << scanner.rest
      lines
    end

    def splitln(str)
      split "#{str}#{eol}"
    end

    def render(line)
      if logger
        logger.debug "render: #{line.inspect}"
      end

      if line.nil?
        return nil 
      end

      match = linebreak.match(line)

      line = match ? $` : line.dup
      line.rstrip! if rstrip
      line.lstrip! if lstrip
      line.tr!("\t", tab) if tab

      match ? "#{indent}#{line}#{eol}" : "#{indent}#{line}"
    end
  end
end