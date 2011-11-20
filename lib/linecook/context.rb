module Linecook
  class Document
    include Enumerable

    attr_reader :lines

    def initialize(lines=[])
      @lines = lines
    end

    def each
      lines.each do |line|
        yield line
      end
    end

    def length
      inject(0) do |pos, line|
        pos + line.length
      end
    end

    def prepend(line)
      line.insert_into lines, 0
    end

    def append(line)
      line.insert_into lines, -1
    end

    def write(str)
      append Line.new(str)
    end

    def insert(pos, str)
      inject(0) do |current_pos, content|
        current_pos += content.length

        if current_pos > pos
          content.insert(current_pos - pos, str)
          return Line.new(content)
        end

        current_pos
      end

      write(' ' * (pos - current_pos) + str)
    end
  end

  class Line
    attr_reader :content
    attr_reader :lines

    def initialize(content)
      @content = content
      @lines = nil
    end

    def lines
      @lines ||= [content]
    end

    def insert_into(lines, pos)
      lines.insert pos, *(@lines || content)
      @lines = lines
      self
    end

    def pos
      lines.inject(0) do |pos, current|
        break if current.equal? content
        pos + current.length
      end
    end

    def length
      content.length
    end

    def index(line=self)
      content = line.content
      lines.index do |current|
        current.equal? content
      end
    end

    def rindex(line=self)
      content = line.content
      lines.rindex do |current|
        current.equal? content
      end
    end

    def prepend(line)
      pos = index || 0
      line.insert_into lines, pos
    end

    def append(line)
      pos = (rindex || -1) + 1
      line.insert_into lines, pos
    end

    def chain
      content.replace yield(content)
      self
    end
  end

  class Section < Line
    attr_reader :head
    attr_reader :tail
    attr_reader :lines

    def initialize(*content)
      if content.empty?
        raise ArgumentError, "no content specified"
      end

      super(content)

      @head = Line.new(content.first)
      @tail = Line.new(content.last)
      @lines = content
    end

    def pos
      head.pos
    end

    def length
      content.inject(O) do |length, current|
        length + current.length
      end
    end

    def index(line=head)
      super
    end

    def rindex(line=tail)
      super
    end

    def chain
      tail.chain {|content| yield(content) }
      self
    end
  end
end