require 'linecook/line'
require 'strscan'

module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines
    attr_accessor :eol
    attr_accessor :indent
    attr_accessor :rstrip
    attr_accessor :lstrip
    attr_reader :linebreak
    attr_reader :logger

    def initialize(lines=[], logger=nil)
      @lines = lines
      @eol = "\n"
      @indent = ""
      @rstrip = false
      @lstrip = false
      @linebreak = /\r?\n/
      @logger = logger
    end

    # Returns the position of the content in lines, or nil if lines does not
    # contain the content.
    def pos(content)
      # in practice it's more likely the content will exist near the end of
      # lines (since that's where rewrites most often occur).  premature
      # optimization sans benchmark.
      lines.rindex do |current|
        current.equal?(content)
      end
    end

    def linebreak=(regex)
      @linebreak = Regexp === regex ? regex : Regexp.new(Regexp.escape(regex))
    end

    def buffer
      buffer = lines.last

      if String === buffer && !buffer.end_with?(eol)
        lines.last
      else
        nil
      end
    end

    def scan(str)
      if logger
        logger.debug "scan: #{str.inspect}"
      end

      if buffer
        str = "#{lines.pop}#{str}"
      end

      scanner = StringScanner.new(str)
      result  = nil

      while line = scanner.scan_until(linebreak)
        result = yield format(line)
      end

      unless scanner.eos?
        result = yield format(scanner.rest)
      end

      result
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

    def write(str)
      scan(str) do |line|
        writelit line
      end
    end

    def writeln(str)
      scan("#{str}#{eol}") do |line|
        writelit line
      end
    end

    def writelit(str)
      if logger
        logger.debug "writelit: #{str.inspect}"
      end

      lines << str
      Line.new(str, self)
    end

    def to_s
      lines.join
    end
  end
end