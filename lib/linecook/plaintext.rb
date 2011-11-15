require 'strscan'

module Linecook
  class Plaintext
    attr_accessor :eol
    attr_accessor :indent
    attr_accessor :rstrip
    attr_accessor :lstrip
    attr_reader :linebreak
    attr_reader :logger

    def initialize(logger=nil)
      @eol = "\n"
      @indent = ""
      @rstrip = false
      @lstrip = false
      @linebreak = /\r?\n/
      @logger = logger
    end

    def linebreak=(regex)
      @linebreak = Regexp === regex ? regex : Regexp.new(Regexp.escape(regex))
    end

    def buffer?(str)
      String === str && !str.end_with?(eol)
    end

    def scan(str)
      if logger
        logger.debug "scan: #{str.inspect}"
      end

      scanner = StringScanner.new(str)
      lines = []

      while line = scanner.scan_until(linebreak)
        lines << format(line)
      end

      unless scanner.eos?
        lines << format(scanner.rest)
      end

      lines
    end

    def scanln(str)
      scan "#{str}#{eol}"
    end

    def format(line)
      if logger
        logger.debug "format: #{line.inspect}"
      end

      unless line =~ linebreak
        return line
      end

      line = $`
      line.rstrip! if rstrip
      line.lstrip! if lstrip

      "#{indent}#{line}#{eol}"
    end
  end
end