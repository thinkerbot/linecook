module Linecook
  class Format
    attr_accessor :eol
    attr_accessor :indent_str
    attr_accessor :indent_level
    attr_accessor :tab
    attr_accessor :rstrip
    attr_accessor :lstrip

    def initialize()
      @eol = nil
      @indent_str = "  "
      @indent_level = 0
      @rstrip = false
      @lstrip = false
      @tab = nil
    end

    def indent
      @indent_str * @indent_level
    end

    def indent=(str)
      @indent_str = str
      @indent_level = 1
    end

    def strip=(value)
      self.lstrip = value
      self.rstrip = value
    end

    def render(line)
      if line.nil?
        return nil 
      end

      endofline = line =~ /\r?\n/ ? (eol || $&) : nil 
      line = $` || line.dup

      line.rstrip! if rstrip
      line.lstrip! if lstrip
      line = "#{indent}#{line}#{endofline}"
      line.tr!("\t", tab) if tab

      line
    end
  end
end