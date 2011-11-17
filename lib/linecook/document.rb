require 'linecook/line'
require 'strscan'

module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines
    attr_reader :logger

    attr_accessor :eol
    attr_writer   :indent
    attr_accessor :indent_str
    attr_accessor :indent_level
    attr_accessor :tab
    attr_accessor :rstrip
    attr_accessor :lstrip
    attr_accessor :linebreak

    def initialize(lines=[], logger=nil)
      @lines = lines
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

    def split(str)
      if logger
        logger.debug "split: #{str.inspect}"
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
      line.tr!("\t", tab) if tab

      "#{indent}#{line}#{eol}"
    end

    def writelit(str)
      newlines = Array === str ? str : [str]
      lines.concat newlines
      Line.new(lines.last, self)
    end

    def write(str)
      buffer = lines.last
      if String === buffer && !buffer.end_with?(eol)
        str = "#{lines.pop}#{str}"
      end

      writelit split(str)
    end

    def writeln(str)
      write "#{str}#{eol}"
    end

    def to_s
      lines.join
    end
  end
end