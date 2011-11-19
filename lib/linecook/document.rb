require 'linecook/line'
require 'linecook/format'

module Linecook
  class Document
    attr_reader :lines
    attr_reader :format

    def initialize(format=nil)
      @lines = []
      @format = (format || Format.new).freeze
    end

    # Returns the position of the content in lines, or nil if lines does not
    # contain the content.
    def pos(line)
      # in practice it's more likely the content will exist near the end of
      # lines (since that's where rewrites most often occur).  premature
      # optimization sans benchmark.
      lines.rindex do |current|
        current.equal?(line)
      end
    end

    def split(str)
      lines = []
      str.each_line("\n") do |line|
        lines << line
      end
      lines
    end

    def insert(pos, str)
      new_lines = split(str)
      previous = pos > 0 ? lines[pos - 1] : nil
      current = lines[pos]

      first = new_lines.first
      if previous && first && !previous.complete?
        previous.suffix new_lines.shift
      end

      last = new_lines.last
      if current && last && !last.end_with?("\n")
        current.prefix new_lines.pop
      end

      new_lines.reverse_each do |new_line|
        lines.insert pos, Line.new(new_line, self)
      end

      lines.last
    end

    def write(str)
      insert lines.length, str
    end

    def writeln(str)
      write "#{str}\n"
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

    def to_s
      lines.join
    end
  end
end