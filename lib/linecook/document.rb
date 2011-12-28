require 'linecook/line'

module Linecook
  class Document
    include Enumerable

    attr_reader :head
    attr_reader :current_line
    attr_reader :tail

    def initialize(line = Line.new)
      @first = @head = @current_line = @tail = @last = line
    end

    # Returns the first line in lines.
    def first
      @first = @first.first  # auto update for prepend
    end

    # Returns the last line in lines.
    def last
      @last = @last.last     # auto update for append
    end

    # Returns an array of lines in self.
    def lines
      map {|line| line }
    end

    # Yields each line in lines to the block.
    def each
      line = first
      while line
        yield line
        line = line.nex
      end
      self
    end

    # Same as each but traverses lines in reverse order.
    def reverse_each
      line = last
      while line
        yield line
        line = line.pre
      end
      self
    end

    # Returns the line at the specified index (lineno). A negative index
    # counts back from last.  Returns nil for an out-of-range index.
    def line(index)
      if index < 0
        index = count + index
        return nil if index < 0
      end

      if index >= 0
        inject(0) do |current, line|
          if current == index
            return line
          end
          current + 1
        end
      end

      nil
    end

    # Writes the string to end of current_line and advances current_line to
    # the last line written.  Returns self.
    def write(str)
      last = current_line.write str

      if current_line == tail
        @tail = last
      end

      @current_line = last
      self
    end

    # Removes lines starting at index.  Returns the line at index.
    def cut(index, length=1)
      if length <= 0
        return nil 
      end

      head = line(index)

      if head
        tail = line(index + length - 1) || last

        pre = head.pre
        nex = tail.nex

        pre.nex = nex if pre
        nex.pre = pre if nex

        head.pre = nil
        tail.nex = nil

        # ensure first and last are pointing at something valid
        @first = @last = pre || nex || Line.new(head.format)
      end

      head
    end

    # Removes any leading empty lines.
    def ltrim
      length = 0
      line = first

      while line.empty? && !line.last?
        length += 1
        line = line.nex
      end

      cut 0, length
    end

    # Removes any trailing empty lines.
    def rtrim
      index = 0
      line = last

      while line.empty? && !line.first?
        index -= 1
        line = line.pre
      end

      cut index, index * -1
    end

    # Removes leading and trailing empty lines.
    def trim
      ltrim
      rtrim
    end

    def reset(line)
      @first = @head = @current_line = @tail = @last = line
    end

    # Clears all lines.
    def clear
      reset Line.new(format)
      self
    end

    # Returns the current format for self (ie the format of current_line).
    def format
      current_line.format
    end

    # Completes the current last line and sets format attributes for the next
    # line.  See set! to change attributes for the last line in place.
    def set(attrs)
      @current_line = current_line.append unless current_line.empty?
      set! attrs
    end

    # Sets format attributes for the last line.
    def set!(attrs)
      new_format = attrs.respond_to?(:call) ? attrs : format.with(attrs)
      current_line.format = new_format
    end

    # Sets format attributes for the duration of a block.
    def with(attrs)
      current = format
      begin
        set attrs
        yield
      ensure
        set current
      end
    end

    # Renders each line to the target.  The render output is appended to
    # target using '<<'.
    def render_to(target)
      each do |line|
        target << line.render
      end
      target
    end

    # Returns the formatted contents of self as a string.
    def to_s
      render_to ""
    end
  end
end