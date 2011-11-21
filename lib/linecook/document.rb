require 'linecook/line'
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

    def pos(line)
      include?(line) ? line.pos : nil
    end

    def length
      lines.inject(0) do |pos, line|
        pos + line.length
      end
    end

    def include?(line)
      lines.any? {|current| current.equal? line }
    end

    def prepend(*new_lines)
      new_lines.reverse_each do |line|
        line.insert_into lines, 0
      end
    end

    def append(*new_lines)
      new_lines.each do |line|
        line.insert_into lines, -1
      end
    end

    def write(str)
      line = Line.new(str, format)
      append line
      line
    end

    def insert(pos, str)
      lines.inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          offset = pos - (current_pos - line.length)
          line.content.insert(offset, str)
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
      target = ""
      lines.each do |line|
        line.render_to target
      end
      target
    end
  end
end