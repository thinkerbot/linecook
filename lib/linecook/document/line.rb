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
      attr_accessor :content

      def initialize(format = Format.new, pre = nil, nex = nil, content = "")
        @format = format
        @pre = pre
        @nex = nex
        @content = content

        if pre
          pre.nex = self
          pre.complete!
        end

        if nex
          nex.pre = self
          self.complete!
        end
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

      # Returns true if content ends with a "\n".
      def complete?
        content[-1] == ?\n
      end

      # Completes the line by adding "\n" to content, if necessary.
      def complete!
        content << "\n" unless complete?
        self
      end

      # Inserts str at the end of content, prior to "\n" if present.
      def write(str)
        insert(complete? ? -2 : -1, str).first
      end

      # Inserts str at the specified column, padding with whitespace and
      # appending new lines as needed.  Returns the line and col after the
      # insert.
      def insert(col, str)
        if col < 0
          col += length + 1
        end

        offset = length - col

        if offset < 0
          eol = complete? ? "\n" : ""
          @content = @content.chomp(eol).ljust(col) + eol
          offset = eol.length
        end

        lines = Line.split @content.insert(col, str.to_s)
        @content = lines.shift

        last = lines.inject(self) do |line, content|
          Line.new(format, line, line.nex, content)
        end
        [last, last.length - offset]
      end

      # Prepends a line. Returns the new line.
      def prepend_line
        Line.new(format, pre, self)
      end

      # Appends a line. Returns the new line.
      def append_line
        Line.new(format, self, nex)
      end

      # Renders self by calling format, if specified.
      def render
        format ? format.call(content) : content
      end

      # Returns the content of self
      def to_s
        content
      end
    end
  end
end