require 'linecook/line'

module Linecook
  class Document
    include Enumerable

    def initialize(first = Line.new)
      @first = first
      @last  = @first.last
    end

    # Returns the first line in lines.
    def first
      @first = @first.first  # auto update for prepend
    end

    # Returns the last line in lines.
    def last
      @last = @last.last     # auto update for append
    end

    # Returns an array of lines in self.
    def lines
      map {|line| line }
    end

    # Yields each line in lines to the block.
    def each
      line = first
      while line
        yield line
        line = line.nex
      end
      self
    end

    # Same as each but traverses lines in reverse order.
    def reverse_each
      line = last
      while line
        yield line
        line = line.pre
      end
      self
    end

    # Returns the length of all content in self
    def length
      inject(0) {|length, line| length + line.length }
    end

    # Returns the line and column at the given position (as an array).
    # Negative positions count back from length.  Returns nil for out-of-range
    # positions.
    def at(pos)
      if pos < 0
        pos = length + pos
      end

      if pos >= 0
        inject(0) do |line_end_pos, line|
          line_end_pos += line.length
          if line_end_pos > pos
            col = pos - line_end_pos + line.length
            return [line, col]
          end
          line_end_pos
        end
      end

      nil
    end

    # Returns the line at the specified index (lineno). A negative index
    # counts back from last.  Returns nil for an out-of-range index.
    def line(index)
      if index < 0
        index = count + index
        return nil if index < 0
      end

      if index >= 0
        inject(0) do |current, line|
          if current == index
            return line
          end
          current + 1
        end
      end

      nil
    end

    # Writes str to last.  Returns last.
    def write(str)
      last.write(str)
      last
    end

    # Writes a line to self and returns the new line.
    def writeln(str)
      write "#{str}\n"
    end

    # Inserts str at the specified pos. Negative positions count back from
    # length.  Raises a RangeError for out-of-range positions.
    def insert(pos, str)
      line, col = at(pos)
      if line.nil?
        raise RangeError, "pos out of range: #{pos}"
      end
      line.insert(col, str)
    end

    # Returns the current format for self (ie the format of last).
    def format
      last.format
    end

    # Sets format attributes (note this resets format to a new object).
    def set(attrs)
      last.append if last.complete?

      new_format  = attrs.respond_to?(:call) ? attrs : format.with(attrs)
      last.format = new_format
    end

    # Sets format attributes for the duration of a block.
    def with(attrs)
      current = format
      begin
        set attrs
        yield
      ensure
        set current
      end
    end

    # Indents n levels for the duration of the block.
    def indent(n=1)
      with(:indent => n) do
        yield
      end
    end

    # Outdents for the duration of the block.  A negative number can be
    # provided to outdent n levels.
    def outdent(n=nil)
      with(:indent => n) do
        yield
      end
    end

    # Renders each line to the target.  The render output is appended to
    # target using '<<'.
    def render_to(target)
      each do |line|
        target << line.render
      end
      target
    end

    # Returns the formatted contents of self as a string.
    def to_s
      render_to ""
    end
  end
end