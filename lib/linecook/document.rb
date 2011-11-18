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
      lines[n]
    end

    def write(str)
      insert lines.length, str
    end

    def writeln(str)
      insertln lines.length, str
    end

    def insert(pos, str)
      insert_lines pos, format.split(str)
    end

    def insertln(pos, str)
      insert_lines pos, format.splitln(str)
    end

    def to_s
      lines.join
    end

    private

    def insert_lines(pos, new_lines) # :nodoc:
      previous = pos > 0 ? lines[pos - 1] : nil
      current = lines[pos]

      if previous && !previous.complete?
        previous.suffix new_lines.shift
      end

      last_new_line = new_lines.last
      if current && last_new_line && !format.complete?(last_new_line)
        current.prefix new_lines.pop
      end

      new_lines.reverse_each do |content|
        lines.insert pos, Line.new(content, self)
      end

      lines.last
    end
  end
end