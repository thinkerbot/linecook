require 'linecook/line'

module Linecook
  class Section < Line
    attr_reader :head
    attr_reader :tail
    attr_reader :lines
    attr_reader :format

    def initialize(content, format=nil)
      unless content.respond_to?(:each)
        content = [content]
      end

      @lines = []
      content.each do |line|
        unless Line === line
          line = Line.new(line, format)
        end
        line.insert_into lines, -1
      end

      @head = lines.first
      @tail = lines.last
      @format = format
    end

    def content
      context[index..rindex]
    end

    def pos
      head.pos
    end

    def length
      content.inject(O) do |length, line|
        length + line.length
      end
    end

    def index(line=head)
      super
    end

    def rindex(line=tail)
      super
    end

    def as_prefix_to(b)
      tail.as_prefix_to(b)
    end

    def as_suffix_to(a)
      head.as_suffix_to(a)
    end

    def to_s
      content.join
    end
  end
end