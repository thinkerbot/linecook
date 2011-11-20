module Linecook
  class Document
    attr_reader :lines

    def initialize(lines=[])
      @lines = lines
    end

    def length
      lines.inject(0) do |pos, line|
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
      lines.inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          line.content.insert(current_pos - pos, str)
          return line
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
      @lines ||= [self]
    end

    def pos
      lines.inject(0) do |pos, current|
        break if current.equal? self
        pos + current.length
      end
    end

    def length
      content.length
    end

    def index(line=self)
      lines.index do |current|
        current.equal? line
      end
    end

    def rindex(line=self)
      lines.rindex do |current|
        current.equal? line
      end
    end

    def prepend(*lines)
      pos = index || 0
      lines.reverse_each do |line|
        line.insert_into lines, pos
      end
    end

    def append(*lines)
      pos = (rindex || -1) + 1
      lines.reverse_each do |line|
        line.insert_into lines, pos
      end
    end

    def rewrite(str)
      content.replace str
    end

    def insert_into(lines, pos)
      lines.insert pos, *(@lines || self)
      @lines = lines
      self
    end

    # b.chain_to(a) a.chain(b)
    def chain_to(a)
      i = index
      j = i + 1
      k = lines.length - j

      head = lines.slice(0, i)
      tail = lines.slice(j, k)

      a.prepend *head
      @content = a.chain(chain_tail)
      a.append *tail
      @lines = a.lines

      self
    end

    def chain(str)
      rewrite "#{chain_head}#{str}"
    end

    def chain_head
      content
    end

    def chain_tail
      content
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

      content.map! do |line|
        Line === line ? line : Line.new(line)
      end

      super(content)

      @head = content.first
      @tail = content.last
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

    def chain(str)
      tail.chain(str)
    end

    def chain_head
      tail.content
    end

    def chain_tail
      head.content
    end
  end

  class Proxy
    attr_reader :_recipe_
    attr_reader :_line_

    def initialize(_recipe_, _line_)
      @_recipe_ = _recipe_
      @_line_ = _line_
    end

    def _chain_to_(another)
      _line_.chain_to(another._line_)
    end
  end

  class Command < Line
    def chain_head
      content.chomp "\n"
    end

    def chain_tail
      " | #{content}"
    end
  end

  class Redirect < Line
    def chain_head
      content.chomp "\n"
    end

    def chain_tail
      " #{content}"
    end
  end

  class Heredoc < Redirect
    def initialize(word, body)
      super(word)
      append body # should be a line
    end
  end

  class CompoundCommand < Section
    def chain_head
      content.chomp "\n"
    end

    def chain_tail
      " | #{content}"
    end
  end

  class If < CompoundCommand
    attr_reader :condition
    attr_reader :body

    def initialize(condition, body)
      super "if", condition, "then", body, "fi"
      @condition = condition
      @body = body
    end

    def elif_(condition, body)
      body.append Elif.new(condition, body)
    end

    def else_(body)
      body.append Else.new(body)
    end
  end

  class Elif < Section
    attr_reader :condition
    attr_reader :body

    def initialize(condition, body)
      super "elif", condition, "then", body
      @condition = condition
      @body = body
    end
  end

  class Else < Section
    attr_reader :body

    def initialize(body)
      super "else", body
      @body = body
    end
  end
end