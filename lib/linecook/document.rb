require 'linecook/line'
require 'linecook/format'

module Linecook
  class Document
    include Enumerable

    def initialize(first=nil, last=nil)
      @first = first
      @last  = last
    end

    def first
      # automatically correct if first has been prepended
      @first ? @first = @first.first : nil
    end

    def last
      # automatically correct if last has been appended
      @last ? @last = @last.last : nil
    end

    def each
      current = first
      while current
        yield current
        current = current.nex
      end
      self
    end

    def reverse_each
      current = last
      while current
        yield current
        current = current.pre
      end
      self
    end

    def pos(line)
      inject(0) do |pos, current|
        return pos if current == line
        pos + 1
      end
    end

    def length
      count
    end

    def at(index)
      if index < 0
        index = length + index
      end

      inject(0) do |pos, line|
        if pos == index
          return line
        end
        pos + 1
      end

      nil
    end

    def next_line(str="")
      if last.nil?
        @first = @last = Line.new(str)
      else
        @last = last.next_line(str)
      end
    end

    def next_section(str, *strs)
      head, tail = next_line(str)

      while str = strs.shift
        tail = tail.append(str)
      end

      @last = tail
      head.down_to(tail)
    end

    def write(str)
      (last || next_line).write(str)
    end

    # Writes a line to self.
    def writeln(str)
      write "#{str}\n"
    end

    def insert(pos, str)
      inject(0) do |current_pos, line|
        current_pos += line.length

        if current_pos > pos
          offset = pos - (current_pos - line.length)
          line.content.insert(offset, str)
          return line
        end

        current_pos
      end

      write(' ' * (pos - current_pos) + str)
    end

    # Returns the formatted contents of self as a string.
    def to_s(target="")
      each do |line|
        target << line.to_s
      end
    end
  end
end