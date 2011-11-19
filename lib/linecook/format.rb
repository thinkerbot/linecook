module Linecook
  class Format
    attr_accessor :eol
    attr_accessor :indent_str
    attr_accessor :indent_level
    attr_accessor :tab
    attr_accessor :rstrip
    attr_accessor :lstrip

    def initialize(attrs={})
      @eol = nil
      @indent_str = "  "
      @indent_level = 0
      @rstrip = false
      @lstrip = false
      @tab = nil
      set(attrs)
    end

    def set(attrs)
      attrs.each_pair do |key, value|
        send "#{key}=", value
      end
    end

    def with(attrs)
      format = dup
      format.set(attrs)
      format
    end

    def indent=(value)
      case value
      when Fixnum
        @indent_level += value
      when String
        @indent_str = value
        @indent_level = 1
      when nil
        @indent_level = 0
      else
        raise "invalid indent: #{value.inspect}"
      end
    end

    def indent
      @indent_str * @indent_level
    end

    def strip=(value)
      @lstrip = value
      @rstrip = value
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