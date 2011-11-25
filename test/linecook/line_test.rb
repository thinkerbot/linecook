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
  # complete? test
  #

  def test_complete_check_returns_true_if_content_ends_with_nl
    line.write "abc"
    assert_equal "abc", line.content
    assert_equal false, line.complete?

    line.write "\n"
    assert_equal "abc\n", line.content
    assert_equal true,    line.complete?
  end

  #
  # write test
  #

  def test_write_writes_to_end_of_line
    a, b, c = abc_lines

    a.write "a"
    c.write "x"
    a.write "bc\n"
    c.write "yz\n"
    assert_equal ["abc\n", "", "xyz\n"], a.lines.map(&:content)
  end

  def test_write_inserts_new_lines_once_complete
    line.write "a"
    line.write "bc\nxyz\n"
    line.write "pqr\n"
    assert_equal ["abc\n", "pqr\n", "xyz\n"], line.lines.map(&:content)
  end

  def test_write_does_nothing_for_empty_str
    line.write ""
    assert_equal [""], line.lines.map(&:content)
  end

  def test_write_propagates_format_to_new_lines
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "abc\nxyz\n"
    assert_equal ["..abc\n", "..xyz\n"], line.lines.map(&:render)
  end

  def test_write_returns_self
    assert_equal line, line.write("str")
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
    line.write "abc"
    line.rewrite "pqr\nxyz"

    assert_equal ["pqr\n", "xyz"], line.lines.map(&:content)
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

  def test_insert_preserves_nl_when_padding
    line.write "abc\n"
    line.insert 6, "xyz"

    assert_equal "abc   xyz\n", line.content
  end

  def test_insert_writes_new_lines_as_needed
    line.write "abc\n"
    line.insert 3, "\npqr\nxyz"

    assert_equal ["abc\n", "pqr\n", "xyz\n"], line.lines.map(&:content)
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

  def test_prepend_prepend_multiple_lines_if_needed
    line.write "xyz\n"
    line.prepend "abc\npqr\n"

    assert_equal ["abc\n", "pqr\n", "xyz\n"], line.lines.map(&:render)
  end

  def test_prepend_propagates_format
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "xyz\n"
    line.prepend "abc\n"

    assert_equal ["..abc\n", "..xyz\n"], line.lines.map(&:render)
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

  def test_append_appends_multiple_lines_if_needed
    line.write "abc\n"
    line.append "pqr\nxyz\n"

    assert_equal ["abc\n", "pqr\n", "xyz\n"], line.lines.map(&:render)
  end

  def test_append_propagates_format
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "abc\n"
    line.append "xyz\n"

    assert_equal ["..abc\n", "..xyz\n"], line.lines.map(&:render)
  end

  #
  # render test
  #

  def test_render_renders_content_by_format
    format = formatter {|str| "..#{str}" }
    line = Line.new format

    line.write "abc\n"
    assert_equal "..abc\n", line.render
  end

  def test_render_completes_incomplete_lines
    a, b, c = abc_lines {|str| "..#{str}" }

    a.write "a\n"
    b.write "b"
    c.write "c\n"

    assert_equal ["..a\n", "..b\n", "..c\n"], a.lines.map(&:render)
  end

  def test_render_does_not_complete_last_line
    a, b, c = abc_lines {|str| "..#{str}" }

    a.write "a\n"
    b.write "b\n"
    c.write "c"

    assert_equal ["..a\n", "..b\n", "..c"], a.lines.map(&:render)
  end
end