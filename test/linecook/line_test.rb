require 'test/unit'
require 'linecook/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Line

  attr_accessor :line

  def setup
    super
    @line = Line.new
  end

  def abc_lines(&format)
    a = Line.new nil, nil, format
    b = Line.new a,   nil, format
    c = Line.new b,   nil, format

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
    line = Line.new {|str| "..#{str}" }
    line.write "abc\nxyz\n"
    assert_equal ["..abc\n", "..xyz\n"], line.lines.map(&:render)
  end

  def test_write_returns_self
    assert_equal line, line.write("str")
  end

  #
  # render test
  #

  def test_render_renders_content_by_format
    line = Line.new {|str| "..#{str}" }
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