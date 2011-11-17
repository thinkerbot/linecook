require 'linecook/line'
require 'linecook/format'

module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines
    attr_reader :format

    def initialize(lines=[], format=nil)
      @lines  = lines
      @buffer = ''
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
      Line.new lines[n], self
    end

    def write(str)
      lines.pop unless @buffer.empty?
      lines.concat format.split("#{@buffer}#{str}", @buffer)
    end

    def writeln(str)
      lines.pop unless @buffer.empty?
      lines.concat format.splitln("#{@buffer}#{str}", @buffer)
    end

    def to_s
      lines.join
    end
  end
end