require 'linecook/line'
require 'linecook/plaintext'

module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines
    attr_reader :format

    def initialize(lines=[], format=nil)
      @lines = lines
      @format = format || Plaintext.new
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

    def buffer
      str = lines.last
      format.buffer?(str) ? str : nil
    end

    def unbuffer
      buffer ? lines.pop : nil
    end

    def writelit(str)
      newlines = Array === str ? str : [str]
      lines.concat newlines
      Line.new(lines.last, self)
    end

    def write(str)
      writelit format.scan("#{unbuffer}#{str}")
    end

    def writeln(str)
      writelit format.scanln("#{unbuffer}#{str}")
    end

    def to_s
      lines.join
    end
  end
end