module Linecook
  class Line
    attr_reader :lines
    attr_reader :content

    def initialize(content="", lines=nil)
      @content = content
      @lines = lines || [content]
    end

    def write(str)
      lines << str
      Line.new(str, lines)
    end

    def pos(content)
      lines.rindex do |current|
        current.equal?(content)
      end
    end

    def prepend(str)
      lines.insert(pos(content), str)
    end

    def prefix(str)
      content.replace "#{str}#{content}"
    end

    def chain(str, eol="\n")
      content.replace "#{content.chomp(eol)}#{str.chomp(eol)}#{eol}"
    end

    def suffix(str)
      content.replace "#{content}#{str}"
    end

    def append(str)
      lines.insert(pos(content) + 1, str)
    end

    def _chain_to_(line)
      line.chain _chain_str_
    end

    def _chain_str_
    end

    def to_s
      lines.join
    end
  end
end