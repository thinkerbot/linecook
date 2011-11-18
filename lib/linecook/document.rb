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
      new_lines = format.split buffer_str(str)
      buffer_write new_lines
    end

    def writeln(str)
      new_lines = format.splitln buffer_str(str)
      buffer_write new_lines
    end

    def to_s
      lines.join
    end

    private

    def buffer_str(str)
      "#{@buffer}#{str}"
    end

    def buffer_write(new_lines)
      last_new_line = new_lines.last

      new_lines.map! {|line| format.render(line) }
      unless @buffer.nil?
        lines.last.replace new_lines.shift
      end
      lines.concat new_lines

      @buffer = format.complete?(lines.last) ? nil : last_new_line
    end
  end
end