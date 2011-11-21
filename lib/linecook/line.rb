module Linecook
  class Line
    attr_reader :content
    attr_reader :format
    attr_reader :lines

    def initialize(content, format=nil)
      @content = content
      @format = format
      @lines = nil
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

    def prepend(*new_lines)
      pos = index || 0
      new_lines.reverse_each do |line|
        line.insert_into lines, pos
      end
      new_lines.first
    end

    def append(*new_lines)
      pos = (rindex || -1) + 1
      new_lines.reverse_each do |line|
        line.insert_into lines, pos
      end
      new_lines.last
    end

    def rewrite(str)
      content.replace str
    end

    def insert_into(lines, index)
      lines.insert index, self
      @lines = lines
      self
    end

    # b.chain_to(a)
    def chain_to(a)
      b = self

      a.rewrite a.as_prefix_to(b)
      b.rewrite b.as_suffix_to(a)

      a.prepend(*@lines.shift(index))
      a.append(*@lines)
      @lines = a.lines

      self
    end

    def as_prefix_to(b)
      content
    end

    def as_suffix_to(a)
      content
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