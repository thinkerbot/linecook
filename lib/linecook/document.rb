require 'linecook/section'
require 'linecook/format'

module Linecook
  class Document
    attr_reader :lines
    attr_reader :format

    def initialize(lines=[], format=nil)
      @lines = lines
      @format = (format || Format.new).freeze
    end

    # Sets format attributes (note this resets format to a new object).
    def set(attrs)
      @format = format.with(attrs).freeze
    end

    # Sets format attributes for the duration of a block.
    def with(attrs)
      current = format
      begin
        set attrs
        yield
      ensure
        @format = current
      end
    end

    def length
      lines.inject(0) do |pos, line|
        pos + line.length
      end
    end

    def prepend(line)
      line.insert_into lines, 0
    end

    def append(line)
      line.insert_into lines, -1
    end

    def write(str)
      append Line.new(str)
    end

    def insert(pos, str)
      lines.inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          line.content.insert(current_pos - pos, str)
          return line
        end

        current_pos
      end

      write(' ' * (pos - current_pos) + str)
    end

    # Writes a line to self.
    def writeln(str)
      write "#{str}\n"
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

    # Returns the formatted contents of self as a string.
    def to_s
      lines.join
    end
  end
end