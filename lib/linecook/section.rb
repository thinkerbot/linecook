module Linecook
  class Section
    attr_reader :lines
    attr_reader :head
    attr_reader :cursor
    attr_reader :tail
    attr_reader :format

    def initialize(lines=[], format=nil)
      if lines.empty?
        lines << Line.new("", lines)
      end

      @lines  = lines
      @head   = lines.first
      @tail   = lines.last
      @cursor = lines.last
      @format = (format || Format.new).freeze
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
      head.index
    end

    def rindex
      cursor.index
    end

    def content
      lines[index..rindex]
    end

    def prepend(*lines)
      @head = head.prepend(*lines)
    end

    def concat(*lines)
      @cursor = cursor.append(*lines)
    end

    def append(*lines)
      @tail = tail.append(*lines)
    end

    # Sets format attributes (note this resets format to a new object).
    def set(attrs)
      @format = format.with(attrs).freeze
    end

    # Sets format attributes for the duration of a block.
    def with(attrs)
      current = format
      begin
        set attrs
        yield
      ensure
        @format = current
      end
    end

    def write(str)
      concat Line.new(str, lines, format)
    end

    # Writes a line to self.
    def writeln(str)
      write "#{str}\n"
    end

    def insert(pos, str)
      lines.inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          offset = pos - (current_pos - line.length)
          line.content.insert(offset, str)
          return line
        end

        current_pos
      end

      write(' ' * (pos - current_pos) + str)
    end

    # Indents n levels for the duration of the block.
    def indent(n=1)
      with(:indent => n) do
        yield
      end
    end

    # Outdents for the duration of the block.  A negative number can be
    # provided to outdent n levels.
    def outdent(n=nil)
      with(:indent => n) do
        yield
      end
    end

    def render_to(target)
      lines.each do |line|
        line.render_to target
      end
    end

    # Returns the formatted contents of self as a string.
    def to_s
      render_to ""
    end
  end
end