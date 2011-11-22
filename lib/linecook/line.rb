module Linecook
  class Line
    attr_reader :str
    attr_accessor :pre
    attr_accessor :nex

    def initialize(str, pre=nil, nex=nil, is_head=true, is_tail=true)
      @str = str
      @pre = pre
      @nex = nex
      @head = is_head
      @tail = is_tail

      pre.nex = self if pre
      nex.pre = self if nex
    end

    def write(str)
      @str << str
    end

    def rewrite(str)
      @str = str
    end

    def length
      str.to_s.length
    end

    def first
      first? ? self : pre.first
    end

    def first?
      pre.nil?
    end

    def last
      last? ? self : nex.last
    end

    def last?
      nex.nil?
    end

    def head
      head? ? self : pre.head
    end

    def head?
      @head || first? || pre.last?
    end

    def tail
      tail? ? self : nex.tail
    end

    def tail?
      @tail || last? || nex.head?
    end

    def prepend(str)
      line = Line.new(str, pre, self, head?, false)
      @head = false
      line
    end

    def append(str)
      line = Line.new(str, self, nex, false, tail?)
      @tail = false
      line
    end

    def next_line(str="")
      tail.append str
    end

    def rel(pos=0)
      case 
      when pos > 0
        nex.at pos - 1
      when pos < 0
        pre.at pos + 1
      else
        self
      end
    end

    def down_to(line=nil, lines=[])
      lines << self
      line == self || last? ? lines : nex.down_to(line, lines)
    end

    def up_to(line=nil, lines=[])
      lines.unshift self
      line == self || first? ? lines : pre.up_to(line, lines)
    end

    def section(start=head, finish=tail)
      lines = up_to(start)
      lines.pop # remove self to prevent duplication
      down_to(finish, lines)
    end
  end
end