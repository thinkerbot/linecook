require 'linecook/document/line'

module Linecook
  class Document
    class Cursor
      attr_accessor :line
      attr_accessor :col

      def initialize(line = Line.new, col = -1)
        @line = line
        @col  = col
      end

      # Writes str to line at col and advances line and col to the end of str.
      def write(str)
        @line, @col = line.insert(col, str)
        self
      end

      # Returns a cursor at the position just prior to self.
      def before
        Cursor.new line, col - 1
      end

      # Returns self.
      def after
        self
      end

      # Returns a cursor at the beginning of line.
      def bol
        Cursor.new line, 0
      end

      # Returns a cursor at the end of line.
      def eol
        Cursor.new line, line.length
      end

      # Inserts a new line above line and returns a cursor to write to it.
      def append
        Cursor.new line.append_line, 0
      end

      # Inserts a new line below line and returns a cursor to write to it.
      def prepend
        Cursor.new line.prepend_line, 0
      end
    end
  end
end