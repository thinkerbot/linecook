module Linecook
  class Line
    attr_reader :str
    attr_accessor :pre
    attr_accessor :nex

    def initialize(str, pre=nil, nex=nil, head=self, tail=self)
      @str = str
      @pre = pre
      @nex = nex
      @head = head
      @tail = tail

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
      @head || (first? ? self : pre.head)
    end

    def tail
      @tail || (last? ? self : nex.tail)
    end

    def next_line(str="")
      current = tail # discover tail only once
      Line.new(str, current, current.nex)
    end

    def prepend(str)
      Line.new(str, pre, head)
    end

    def append(str)
      line  = Line.new(str, tail, nex, nil)
      @tail = nil
      line
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
  end
end