require 'strscan'

module Linecook
  class Line
    attr_accessor :pre
    attr_accessor :nex
    attr_reader :format
    attr_reader :content

    def initialize(pre=nil, nex=nil, format=nil, content="")
      @pre = pre
      @nex = nex

      pre.nex = self if pre
      nex.pre = self if nex

      @format  = format || (block_given? ? Proc.new : nil)
      @content = content
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

    def lines
      current = first
      lines = [current]

      while !current.last?
        current = current.nex
        lines << current
      end

      lines
    end

    def lineno
      pre ? pre.lineno + 1 : 0
    end

    def complete?
      content[-1] == ?\n
    end

    def scan(str)
      lines = []
      scanner = StringScanner.new(str)
      while line = scanner.scan_until(/\n/)
        lines << line
      end
      unless scanner.eos?
        lines << scanner.rest
      end
      lines
    end

    def write(str)
      lines = scan(str)

      unless complete? || lines.empty?
        content << lines.shift
      end

      lines.inject(self) do |tail, content|
        Line.new(tail, tail.nex, format, content) 
      end

      self
    end

    def rewrite(str)
      content.clear
      write(str)
    end

    def insert(col, str)
      rewrite content.insert(col, str)
    end

    def length
      content.length
    end

    def prepend(str=nil)
      line = Line.new(pre, self, format)
      line.write(str) if str
      line
    end

    def append(str=nil)
      line = Line.new(self, nex, format)
      line.write(str) if str
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

    def render
      str = complete? || last? ? content : "#{content}\n"
      format ? format.call(str) : str
    end

    def to_s
      content
    end
  end
end