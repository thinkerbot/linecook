require 'linecook/format'
require 'strscan'

module Linecook
  class Line
    class << self
      # Splits str into an array of line content. For example:
      #
      #   Line.split "abc\nxyz\n"  # => ["abc", "xyz", ""]
      #   Line.split "\nabc\nxyz"  # => ["", "abc", "xyz"]
      #
      def split(str)
        lines = []
        scanner = StringScanner.new(str)
        while line = scanner.scan_until(/\n/)
          lines << line.chomp("\n")
        end
        lines << scanner.rest
        lines
      end
    end
    include Enumerable

    # The format for self
    attr_accessor :format

    # The previous line, or nil if first in lines
    attr_accessor :pre

    # The next line, or nil if last in lines
    attr_accessor :nex

    # The unformatted content for self.
    attr_reader   :content

    def initialize(format = Format.new, pre = nil, nex = nil, content = "")
      @format = format
      @pre = pre
      @nex = nex

      pre.nex = self if pre
      nex.pre = self if nex

      @content = content
    end

    # Returns the first line in lines.
    def first
      first? ? self : pre.first
    end

    # True if self is the first line in lines.
    def first?
      pre.nil?
    end

    # Returns the last line in lines.
    def last
      last? ? self : nex.last
    end

    # True if self is the last line in lines.
    def last?
      nex.nil?
    end

    # Returns true if content is empty.
    def empty?
      content.empty?
    end

    # Returns an array of lines that self is a part of.
    def lines
      lines = []
      line  = first
      while line
        lines << line
        line = line.nex
      end
      lines
    end

    # Returns the position of content in lines (ie assuming the content of all
    # the lines were joined together).
    def pos
      first? ? 0 : pre.pos + pre.length
    end

    # Returns the length of content
    def length
      content.length
    end

    # Returns the index of self in lines.
    def lineno
      pre ? pre.lineno + 1 : 0
    end

    # Writes str to the end of content, appending a new line for every "\n".
    # New lines will have the same format as self.  Returns the last line
    # written (usually self).
    def write(str)
      lines = Line.split(str.to_s)
      content << lines.shift

      last = self
      lines.inject(self) do |line, content|
        last = Line.new(format, line, line.nex, content)
      end

      last
    end

    # Writes str to the start of content, prepending a new line for every
    # "\n". New lines will have the same format as self.  Returns the first
    # line written (usually self).
    def prewrite(str)
      lines = Line.split(str.to_s)
      content.replace "#{lines.pop}#{content}"

      first = self
      lines.inject(pre) do |line, content|
        first = Line.new(format, line, line ? line.nex : self, content)
      end

      first
    end

    # Rewrites the content of self and appends new lines as per write. Returns
    # the last line written (usually self).
    def rewrite(str)
      @content = ""
      write(str)
    end

    # Inserts str at the specified column in self, padding with whitespace if
    # needed.  New lines are appended as per write.  Returns the last line
    # written (usually self).
    def insert(col, str)
      if col > length
        content.replace content.ljust(col)
      end

      rewrite content.insert(col, str.to_s)
    end

    # Prepends a line and writes str, if specified.  The prepended line will
    # have the same format as self.
    def prepend(str=nil)
      line = Line.new(format, pre, self)
      line.write(str) if str
      line
    end

    # Appends a line and writes str, if specified.  The appended line will
    # have the same format as self.
    def append(str=nil)
      line = Line.new(format, self, nex)
      line.write(str) if str
      line
    end

    # Prepends the lines of line to self.  Returns the first prepended line.
    def prepend_line(line)
      head = line.first
      tail = line.last

      head.pre = pre
      pre.nex  = head if pre

      tail.nex = self
      self.pre = tail

      head
    end

    # Appends the lines of line to self.  Returns the last appended line.
    def append_line(line)
      head = line.first
      tail = line.last

      tail.nex = nex
      nex.pre  = tail if nex

      head.pre = self
      self.nex = head

      tail
    end

    # Renders content using `format.call`.
    def render
      format.call(content)
    end

    # Returns content.
    def to_s
      content
    end
  end
end