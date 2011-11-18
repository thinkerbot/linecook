require 'linecook/line'
require 'linecook/format'

module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines
    attr_reader :format

    def initialize(lines=[], format=nil)
      @lines  = lines
      @format = format || Format.new
      @buffer = nil
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

    def line(n=-1)
      Line.new lines[n], self
    end

    def write(str)
      lines = format.split buffer_str(str)
      buffer_write lines
    end

    def writeln(str)
      lines = format.splitln buffer_str(str)
      buffer_write lines
    end

    def insertln(pos, str)
      lines = format.splitln buffer_str(str, pos)
      buffer_write lines, pos
    end

    def to_s
      lines.join
    end

    private

    def buffer_pos
      lines.length
    end

    def buffer_pos?(pos=buffer_pos)
      pos == buffer_pos && @buffer != nil
    end

    def buffer_str(str, pos=buffer_pos)
      buffer_pos?(pos) ? "#{@buffer}#{str}" : str
    end

    def buffer_write(raw_lines, pos=buffer_pos)
      new_lines = raw_lines.map {|line| format.render(line) }

      if buffer_pos?(pos)
        lines.last.replace new_lines.shift
      end
      lines.insert pos, *new_lines

      last_line = Line.new(lines.last, self)
      @buffer = last_line.complete? ? nil : raw_lines.last

      last_line
    end
  end
end