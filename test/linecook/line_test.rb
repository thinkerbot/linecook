require File.expand_path('../../test_helper', __FILE__)
require 'linecook/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Line

  attr_accessor :line

  def setup
    super
    @line = Line.new
  end

  def abc_lines(&format)
    a = Line.new format, nil, nil
    b = Line.new format, a,   nil
    c = Line.new format, b,   nil

    [a,b,c]
  end

  def xyz_lines(&format)
    x = Line.new format, nil, nil
    y = Line.new format, x,   nil
    z = Line.new format, y,   nil

    [x,y,z]
  end

  #
  # first test
  #

  def test_first_returns_first_line_in_lines
    a, b, c = abc_lines

    assert_equal a, a.first
    assert_equal a, c.first
  end

  #
  # first? test
  #

  def test_first_check_returns_true_if_line_is_first_in_lines
    a, b, c = abc_lines

    assert_equal true,  a.first?
    assert_equal false, c.first?
  end

  #
  # last test
  #

  def test_last_returns_last_line_in_lines
    a, b, c = abc_lines

    assert_equal c, a.last
    assert_equal c, c.last
  end

  #
  # last? test
  #

  def test_last_check_returns_true_if_line_is_last_in_lines
    a, b, c = abc_lines

    assert_equal false, a.last?
    assert_equal true,  c.last?
  end

  #
  # empty? test
  #

  def test_empty_check_returns_true_if_line_content_is_empty
    assert_equal true, line.empty?
    line.write ' '
    assert_equal false, line.empty?
  end

  #
  # lines test
  #

  def test_lines_returns_array_of_lines_between_first_and_last
    a, b, c = abc_lines

    assert_equal [a, b, c], a.lines
    assert_equal [a, b, c], c.lines
  end

  #
  # lineno test
  #

  def test_lineno_is_zero_for_new_line
    assert_equal 0, line.lineno
  end

  def test_lineno_is_index_in_lines
    a, b, c = abc_lines

    assert_equal 0, a.lineno
    assert_equal 1, b.lineno
    assert_equal 2, c.lineno
  end

  #
  # write test
  #

  def test_write_writes_to_end_of_line
    line.write "a"
    line.write "b"
    line.write "c"
    assert_equal "abc", line.content
  end

  def test_write_appends_lines_on_NL
    line.write "ab\n\n"
    assert_equal ["ab", "", ""], line.lines.map(&:content)

    line.write "c\nxyz"
    assert_equal ["abc", "xyz", "", ""], line.lines.map(&:content)
  end

  def test_write_converts_input_to_s
    line.write :str
    assert_equal "str", line.content
  end

  def test_write_propagates_format_to_new_lines
    format = lambda {|str, first, last| "..#{str}" }
    line = Line.new format

    line.write "abc\nxyz"
    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  def test_write_returns_last_line_written
    assert_equal "xyz", line.write("abc\nxyz").content
  end

  #
  # prewrite test
  #

  def test_prewrite_writes_to_start_of_line
    line.prewrite "c"
    line.prewrite "b"
    line.prewrite "a"
    assert_equal "abc", line.content
  end

  def test_prewrite_prepends_lines_on_NL
    line.write "yz"
    line.prewrite "abc\n\nx"
    assert_equal ["abc", "", "xyz"], line.lines.map(&:content)
  end

  def test_prewrite_converts_input_to_s
    line.prewrite :str
    assert_equal "str", line.content
  end

  def test_prewrite_propagates_format_to_new_lines
    format = lambda {|str, first, last| "..#{str}" }
    line = Line.new format

    line.prewrite "abc\nxyz"
    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  def test_prewrite_returns_first_line_written
    assert_equal "abc", line.prewrite("abc\nxyz").content
  end

  #
  # prepend test
  #

  def test_prepend_prepend_a_line_to_self
    line.write "xyz"
    line.prepend "abc"
    line.prepend "pqr"

    assert_equal ["abc", "pqr", "xyz"], line.lines.map(&:content)
  end

  def test_prepend_prepends_multiple_lines_on_NL
    line.write "xyz"
    line.prepend "abc\npqr"

    assert_equal ["abc", "pqr", "xyz"], line.lines.map(&:content)
  end

  def test_prepend_propagates_format
    format = lambda {|str, first, last| "..#{str}" }
    line = Line.new format

    line.write "xyz"
    line.prepend "abc"

    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  def test_prepend_returns_first_line_prepended
    line.write "xyz"
    assert_equal "abc", line.prepend("abc\npqr").content
  end

  #
  # append test
  #

  def test_append_appends_a_line_to_self
    line.write "abc"
    line.append "xyz"
    line.append "pqr"

    assert_equal ["abc", "pqr", "xyz"], line.lines.map(&:content)
  end

  def test_append_appends_multiple_lines_on_NL
    line.write "abc"
    line.append "pqr\nxyz"

    assert_equal ["abc", "pqr", "xyz"], line.lines.map(&:content)
  end

  def test_append_propagates_format
    format = lambda {|str, first, last| "..#{str}" }
    line = Line.new format

    line.write "abc"
    line.append "xyz"

    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  def test_append_returns_the_last_line_appended
    line.write "abc"
    assert_equal "xyz", line.append("pqr\nxyz").content
  end

  #
  # prepend_line
  #

  def test_prepend_line_inserts_lines_as_pre
    a, b, c = abc_lines
    x, y, z = xyz_lines

    assert_equal x, b.prepend_line(y)
    assert_equal [a, x, y, z, b, c], a.lines
  end

  #
  # append_line
  #

  def test_append_line_inserts_lines_as_nex
    a, b, c = abc_lines
    x, y, z = xyz_lines

    assert_equal z, b.append_line(y)
    assert_equal [a, b, x, y, z, c], a.lines
  end

  #
  # render test
  #

  def test_render_renders_content_by_calling_format
    format = lambda {|str, first, last| "..#{str}\n" }
    line = Line.new format

    line.write "abc"
    assert_equal "..abc\n", line.render
  end
end