module Linecook
  class Format
    attr_accessor :eol
    attr_accessor :indent_str
    attr_reader   :indent_level
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

    def indent_level=(value)
      if value < 0
        raise "indent level cannot be set to negative value: #{value}"
      end
      @indent_level = value
    end

    def indent=(value)
      case value
      when Fixnum
        self.indent_level += value
      when String
        self.indent_str = value
        self.indent_level = 1
      when nil
        self.indent_level = 0
      else
        raise "invalid indent: #{value.inspect}"
      end
    end

    def indent
      indent_str * indent_level
    end

    def strip=(value)
      self.lstrip = value
      self.rstrip = value
    end

    def render(str, first=false, last=false)
      # strip
      if lstrip
        pattern = first ? /(\A|\n)([^\n]+)/ : /(\n)([^\n]+)/
        str.gsub!(pattern) { "#{$1}#{$2.lstrip}" }
      end

      if rstrip
        pattern = last ? /\s+?(\r?\n|\z)/ : /\s+?(\r?\n)/
        str.gsub!(pattern) { $1 }
      end

      # indent
      unless indent.empty?
        pattern = first ? 
          (last ? /(\A|\n)./ : /(\A|\n)/) :
          (last ? /(\n)./ : /(\n)/)
        str.gsub!(pattern) { "#{$1}#{indent}" }
      end

      # tr eol
      str.gsub!(/\r?\n/, eol) if eol

      # expand tab
      str.tr!("\t", tab) if tab

      str
    end
  end
end