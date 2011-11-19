module Linecook
  class Format
    attr_reader :eol
    attr_reader :indent_str
    attr_reader :indent_level
    attr_reader :tab
    attr_reader :rstrip
    attr_reader :lstrip

    def initialize(attrs={})
      @eol = nil
      @indent_str = "  "
      @indent_level = 0
      @rstrip = false
      @lstrip = false
      @tab = nil
      set(attrs)
    end

    def with(attrs)
      format = dup
      format.set(attrs)
      format
    end

    def set(attrs)
      attrs.each_pair do |key, value|
        case key
        when :indent
          @indent_str = value
          @indent_level = 1
        when :indent_str
          @indent_str = value
        when :indent_level
          @indent_level = value
        when :strip
          @lstrip = value
          @rstrip = value
        when :rstrip
          @rstrip = value
        when :lstrip
          @lstrip = value
        when :eol
          @eol = value
        when :tab
          @tab = value
        else
          raise "unknown attribute: #{key.inspect}"
        end
      end
    end

    def indent
      @indent_str * @indent_level
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