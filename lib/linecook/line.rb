module Linecook
  class Line
    attr_reader :content
    attr_reader :lines
    attr_reader :format

    def initialize(content, lines=[], format=nil)
      @content = content
      @lines   = lines
      @format  = format
    end

    def rewrite(content)
      @content = content
    end

    def pos
      lines.inject(0) do |pos, current|
        return pos if current.equal? self
        pos + current.length
      end
      nil
    end

    def length
      content.length
    end

    def index
      lines.index do |current|
        current.equal? self
      end
    end

    def rindex
      lines.rindex do |current|
        current.equal? self
      end
    end

    def prepend(*lines)
      self.lines.insert(index || 0, *lines)
      lines.last
    end

    def append(*lines)
      self.lines.insert((rindex || -1) + 1, *lines)
      lines.last
    end

    def render_to(target)
      if format
        format.render(content, target)
      else
        target << content
      end
    end
  end
end