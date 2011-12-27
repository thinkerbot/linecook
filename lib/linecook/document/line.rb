require 'linecook/document/format'
require 'strscan'

module Linecook
  class Document
    class Line
      class << self
        # Splits str into an array of lines, preserving end-of-line
        # characters. For example:
        #
        #   Line.split "abc\nxyz\n"  # => ["abc\n", "xyz\n"]
        #   Line.split "\nabc\nxyz"  # => ["\n", "abc\n", "xyz"]
        #
        def split(str)
          lines = []
          scanner = StringScanner.new(str)
          while line = scanner.scan_until(/\n/)
            lines << line
          end
          unless scanner.eos?
            lines << scanner.rest
          end
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

      # The unformatted content for self
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

      # Returns the position of content in lines (ie assuming the content of
      # all the lines were joined together).
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

      # Returns true if content ends with a newline character.
      def complete?
        content[-1] == ?\n
      end

      # Writes str to the end of content, appending new lines if necessary
      # once the content is a complete line (ie ends in "\n").  New lines will
      # have the same format as self.  Returns self.
      def write(str)
        lines = Line.split(str.to_s)

        unless complete? || lines.empty?
          content << lines.shift
        end

        last = self
        lines.inject(self) do |tail, content|
          last = Line.new(format, tail, tail.nex, content)
        end

        last
      end

      # Rewrites the content of self and appends new lines as per write.
      # Returns self.
      def rewrite(str)
        @content = ""
        write(str)
      end

      # Inserts str at the specified column in self, padding with whitespace
      # if needed.  New lines are appended as per write.  Returns self.
      def insert(col, str)
        ncols = length
        ncols -= 1 if complete?

        if col > ncols
          eol = complete? ? "\n" : ""
          content.replace content.chomp(eol).ljust(col) + eol
        end

        rewrite content.insert(col, str.to_s)
      end

      # Inserts str to self, prior to the end of line (if present).  If there
      # is no existing content, or if the only content is a newline, then
      # chain is equivalent to write.
      def chain(str)
        if complete?
          content.chomp!("\n")
          str = "#{str}\n"
        end

        write str
        self
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

      # Renders self by calling format, if specified.  Render adds "\n" to
      # incomplete content, unless self is the last line.
      def render
        line = complete? || last? ? content : "#{content}\n"
        format ? format.call(line) : line
      end

      # Returns the content of self
      def to_s
        content
      end
    end
  end
end