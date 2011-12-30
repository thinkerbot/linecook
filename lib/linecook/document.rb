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

    # Returns the line at the specified index (lineno) in lines. A negative
    # index counts back from last.  Returns nil for an out-of-range index.
    def line(index)
      if index >= 0
        current = 0
        each do |line|
          if current == index
            return line
          end
          current += 1
        end
      else
        current = -1
        reverse_each do |line|
          if current == index
            return line
          end
          current -= 1
        end
      end

      nil
    end

    # Sets current_line, head, and tail.
    def set_marks(line, head=line, tail=line)
      @current_line = line
      @head = head
      @tail = tail
      self
    end

    # Set marks for the duration of a block.
    def with_marks(line, head=line, tail=line)
      current = marks
      begin
        set_marks(line, head, tail)
        yield
      ensure
        set_marks *current
      end
    end

    # Returns the marks (current_line, head, tail) as an array.
    def marks
      [current_line, head, tail]
    end

    # Returns true if the current line is not empty.
    def chain?
      !current_line.empty?
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

    # Prepends the string to head with the format attrs (head remains the
    # same).  Returns self.
    def prepend(str, attrs=nil)
      new_format = attrs ? format.with(attrs) : format
      head.prepend str, new_format
      self
    end

    # Appends the string to tail with the format attrs and advances both tail
    # to the last line appended. Returns self.
    def append(str, attrs=nil)
      new_format = attrs ? format.with(attrs) : format
      @tail = tail.append str, new_format
      self
    end

    # Prepends a line to head.
    def prepend_line(line)
      head.prepend_line line
      self
    end

    # Appends a line to tail and advances tail to the last line added.
    def append_line(line)
      @tail = tail.append_line line
      self
    end

    # Resets all lines to line (effectively changing the doc).
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