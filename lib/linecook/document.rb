module Linecook
  class Document
    # An array of lines in the document.
    attr_reader :lines

    def initialize(lines=[])
      @lines = lines
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
  end
end