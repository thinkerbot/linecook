require 'linecook/line'
require 'linecook/format'

module Linecook
  class Document
    include Enumerable

    def initialize(format = Format.new)
      @first = @last = Line.new(nil, nil, format)
    end

    def first
      # automatically correct if first has been prepended
      @first = @first.first
    end

    def last
      # automatically correct if last has been appended
      @last = @last.last
    end

    def lines
      map
    end

    def each
      current = first
      while current
        yield current
        current = current.nex
      end
      self
    end

    def reverse_each
      current = last
      while current
        yield current
        current = current.pre
      end
      self
    end

    def pos(line)
      inject(0) do |pos, current|
        return pos if current == line
        pos + 1
      end
    end

    def length
      count
    end

    def at(index)
      if index < 0
        index = length + index
      end

      inject(0) do |pos, line|
        if pos == index
          return line
        end
        pos + 1
      end

      nil
    end

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

    def write(str)
      last.write(str)
    end

    # Writes a line to self.
    def writeln(str)
      write "#{str}\n"
    end

    def insert(pos, str)
      inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          col = pos - (current_pos - line.length)
          line.insert(col, str)
          return line
        end

        current_pos
      end

      write(' ' * (pos - current_pos) + str)
    end

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