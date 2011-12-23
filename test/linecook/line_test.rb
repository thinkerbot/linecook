require File.expand_path('../../test_helper', __FILE__)
require 'linecook/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Line

  attr_accessor :line

  def setup
    super
    @line = Line.new
  end

  def formatter(&block)
    block
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
  # pos test
  #

  def test_pos_returns_the_position_of_content_in_lines
    a, b, c = abc_lines
    a.write "abc"
    b.write "abc"
    c.write "abc"

    assert_equal 0, a.pos
    assert_equal 3, b.pos
    assert_equal 6, c.pos
  end

  #
  # length test
  #

  def test_length_returns_the_length_of_content
    line.write "abc"
    assert_equal 3, line.length
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
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "abc\nxyz"
    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  def test_write_returns_last_line_written
    assert_equal "xyz", line.write("abc\nxyz").content
  end

  #
  # rewrite test
  #

  def test_rewrite_replaces_content_for_self
    line.write "abc"
    line.rewrite "xyz"

    assert_equal "xyz", line.content
  end

  def test_rewrite_appends_lines_as_needed
    line.write "ABC\n\n"
    assert_equal ["ABC", "", ""], line.lines.map(&:content)

    line.rewrite "abc\nxyz"
    assert_equal ["abc", "xyz", "", ""], line.lines.map(&:content)
  end

  def test_rewrite_converts_input_to_s
    line.write "abc"
    line.rewrite :xyz

    assert_equal "xyz", line.content
  end

  #
  # insert test
  #

  def test_insert_inserts_content_at_col
    line.write "ac"
    line.insert 1, "b"

    assert_equal "abc", line.content
  end

  def test_insert_pads_to_col_if_needed
    line.write "abc"
    line.insert 6, "xyz"

    assert_equal "abc   xyz", line.content
  end

  def test_insert_appends_new_lines_as_needed
    line.write "ab\n"
    line.insert 2, "c\nxyz"

    assert_equal ["abc", "xyz", ""], line.lines.map(&:content)
  end

  def test_insert_converts_input_to_s
    line.write "ac"
    line.insert 1, :b

    assert_equal "abc", line.content
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
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "xyz"
    line.prepend "abc"

    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
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
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "abc"
    line.append "xyz"

    assert_equal ["..abc", "..xyz"], line.lines.map(&:render)
  end

  #
  # render test
  #

  def test_render_renders_content_by_calling_format
    format = formatter {|str| "..#{str}\n" }
    line = Line.new format

    line.write "abc"
    assert_equal "..abc\n", line.render
  end
end