module Linecook
  class Section
    attr_reader :lines
    attr_reader :head
    attr_reader :tail
    attr_reader :format

    def initialize(lines, format=nil)
      unless lines.respond_to?(:each)
        lines = [lines]
      end

      @lines = lines
      @head = @lines.first
      @tail = @lines.last
      @format = format
    end

    def pos
      head.pos
    end

    def length
      content.inject(O) do |length, line|
        length + line.length
      end
    end

    def index
      line.index
    end

    def rindex
      tail.rindex
    end

    def content
      lines[index..rindex]
    end

    def prepend(*new_lines)
      head.prepend(*new_lines)
    end

    def append(*new_lines)
      tail.append(*new_lines)
    end

    def insert_into(lines, index)
      lines.insert index, *content
      @lines = lines
      self
    end

    def chain_to(a)
      head.chain_to(a)
    end

    def as_prefix_to(b)
      tail.as_prefix_to(b)
    end

    def as_suffix_to(a)
      head.as_suffix_to(a)
    end

    def render_to(target)
      content.each do |line|
        line.render_to target
      end
    end

    # Returns the formatted contents of self as a string.
    def to_s
      render_to ""
    end
  end
end