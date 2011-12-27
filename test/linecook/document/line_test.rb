require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/document/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Document::Line

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

  #
  # initialize test
  #

  def test_initialize_completes_pre
    a = Line.new
    b = Line.new nil, a
    assert_equal true, a.complete?
  end

  def test_initialize_completes_self_if_nex
    b = Line.new
    a = Line.new nil, nil, b
    assert_equal true, a.complete?
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
    b.write "pqr"
    c.write "xyz"

    assert_equal 0, a.pos
    assert_equal 4, b.pos
    assert_equal 8, c.pos
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
  # complete! test
  #

  def test_complete_bang_completes_content_with_LF_if_needed
    line.write "abc"

    line.complete!
    assert_equal "abc\n", line.content

    line.complete!
    assert_equal "abc\n", line.content
  end

  #
  # write test
  #

  def test_write_inserts_str_at_eol_before_NL
    line.write "a"
    line.write "b\n"
    line.write "c"

    assert_equal "abc\n", line.content
  end

  def test_write_returns_last_line_to_recieve_content
    a = line.write "a"
    b = line.write "bc\n"
    x = line.write "\n\nxyz"

    assert_equal "abc\n", a.content
    assert_equal "abc\n", b.content
    assert_equal "xyz\n", x.content
  end

  #
  # insert test
  #

  def test_insert_inserts_content_at_col
    line.insert 0, "ac"
    line.insert 1, "b"

    assert_equal "abc", line.content
  end

  def test_insert_appends_new_lines_for_content_after_LF
    line.insert 0, "abc\n\nxyz\n"
    assert_equal ["abc\n", "\n", "xyz\n"], line.lines.map(&:content)
  end

  def test_insert_completes_appended_lines_if_not_last
    line = Line.new
    line.insert 0, "abc\nxyz"
    assert_equal ["abc\n", "xyz"], line.lines.map(&:content)

    line.insert 4, "pqr"
    assert_equal ["abc\n", "pqr\n", "xyz"], line.lines.map(&:content)
  end

  def test_insert_returns_last_line_and_col_to_recieve_content
    l, pos = line.insert 0, "abc"
    assert_equal "abc", l.content
    assert_equal 3, pos
  end

  def test_insert_into_content
    line.insert 0, "ac\n"
    l, pos = line.insert 1, "b"

    assert_equal "abc\n", l.content
    assert_equal 2, pos
    assert_equal ["abc\n"], line.lines.map(&:content)
  end

  def test_insert_multiple_lines_before_LF
    line.insert 0, "ab\n"
    l, pos = line.insert 2, "c\nxyz"

    assert_equal "xyz\n", l.content
    assert_equal 3, pos
    assert_equal ["abc\n", "xyz\n"], line.lines.map(&:content)
  end

  def test_insert_multiple_lines_after_LF
    line.insert 0, "abc\n"
    l, pos = line.insert 4, "\nxyz"

    assert_equal "xyz", l.content
    assert_equal 3, pos
    assert_equal ["abc\n", "\n", "xyz"], line.lines.map(&:content)
  end

  def test_insert_pads_to_col_if_needed
    line.insert 0, "abc"
    l, pos = line.insert 6, "xyz"

    assert_equal "abc   xyz", l.content
    assert_equal 9, pos
    assert_equal ["abc   xyz"], line.lines.map(&:content)
  end

  def test_insert_preserves_nl_when_padding
    line.insert 0, "abc\n"
    l, pos = line.insert 6, "xyz"

    assert_equal "abc   xyz\n", l.content
    assert_equal 9, pos
    assert_equal ["abc   xyz\n"], line.lines.map(&:content)
  end

  def test_insert_multiple_lines_padding
    line.insert 0, "abc\n"
    l, pos = line.insert 6, "pqr\nxyz"

    assert_equal "xyz\n", l.content
    assert_equal 3, pos
    assert_equal ["abc   pqr\n", "xyz\n"], line.lines.map(&:content)
  end

  def test_insert_supports_negative_col
    line.insert 0, "ac\n"
    l, pos = line.insert -3, "b"

    assert_equal "abc\n", l.content
    assert_equal 2, pos
    assert_equal ["abc\n"], line.lines.map(&:content)
  end

  def test_insert_propagates_format
    format = lambda {|str| "..#{str}" }
    a = Line.new format
    b, bpos = a.insert(0, "abc\nxyz")

    assert_equal format, b.format
  end

  def test_insert_converts_input_to_s
    line.insert 0, :abc
    assert_equal "abc", line.content
  end

  #
  # prepend_line
  #

  def test_prepend_line_propagates_format
    format = lambda {|str| }
    b = Line.new format
    a = b.prepend_line
    assert_equal format, a.format
  end

  def test_prepend_line_completes_new_line
    new_line = line.prepend_line
    assert_equal true,  new_line.complete?
    assert_equal false, line.complete?
  end

  #
  # append_line
  #

  def test_append_line_propagates_format
    format = lambda {|str| }
    a = Line.new format
    b = a.append_line
    assert_equal format, b.format
  end

  def test_append_line_completes_self
    new_line = line.append_line
    assert_equal true,  line.complete?
    assert_equal false, new_line.complete?
  end

  #
  # render test
  #

  def test_render_renders_content_by_format
    format = lambda {|str| "..#{str}\n" }
    line = Line.new format
    line.write "abc"
    assert_equal "..abc\n", line.render
  end
end