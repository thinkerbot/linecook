module Linecook
  class Line
    attr_reader :content
    attr_reader :document
    attr_reader :format

    def initialize(content="", document=nil)
      @content = content
      @document = document || Document.new([content])
      @format = document.format
    end

    def pos
      document.pos(content)
    end

    def prepend(str)
      document.insert(pos, str)
    end

    def prefix(str)
      content.replace "#{str}#{content}"
    end

    def chain(str)
      content.replace "#{content.chomp(eol)}#{str.chomp(eol)}#{eol}"
    end

    def suffix(str)
      content.replace "#{content}#{str}"
    end

    def append(str)
      document.insert(pos + 1, str)
    end

    def complete?
      format.complete?(content)
    end

    def _chain_to_(line)
      line.chain _chain_str_
    end

    def _chain_str_
    end

    def to_s
      content
    end
  end
end