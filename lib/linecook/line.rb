module Linecook
  class Line
    attr_reader :content
    attr_reader :doc
    attr_reader :format

    def initialize(content="", doc=nil)
      @content = content
      @doc = doc || Document.new([content])
      @format = doc.format
    end

    def pos
      doc.pos(self)
    end

    def prepend(str)
      doc.insert(pos, str)
    end

    def prefix(str)
      content.replace "#{str}#{content}"
    end

    def chain(str)
      head = content =~ /\r?\n/ ? $` : content
      tail = str =~ /\r?\n/ ? $` : str
      content.replace "#{head}#{tail}\n"
    end

    def suffix(str)
      content.replace "#{content}#{str}"
    end

    def append(str)
      doc.insert(pos + 1, str)
    end

    def complete?
      content.end_with?("\n")
    end

    def _chain_to_(line)
      line.chain _chain_str_
    end

    def _chain_str_
    end

    def to_s
      format.render(content)
    end
  end
end