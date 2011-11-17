require 'test/unit'
require 'linecook/format'
require 'logger'

class FormatTest < Test::Unit::TestCase
  Format = Linecook::Format

  attr_accessor :format

  def setup
    super
    logger = $DEBUG ? Logger.new(STDOUT) : nil
    puts if logger
    @format = Format.new(logger)
  end

  #
  # split test
  #

  def test_split_splits_str_along_nl
    assert_equal ["abc\n", "xyz\n", ""], format.split("abc\nxyz\n")
  end

  def test_split_splits_str_along_crnl
    assert_equal ["abc\r\n", "xyz\r\n", ""], format.split("abc\r\nxyz\r\n")
  end

  def test_split_renders_split_strings
    format.indent = '  '
    assert_equal ["  abc\n", "  xyz\n", ""], format.split("abc\nxyz\n")
  end

  def test_split_does_not_render_incomplete_lines
    format.indent = '  '
    assert_equal ["  abc\n", "xyz"], format.split("abc\nxyz")
  end

  #
  # splitln test
  #

  def test_splitln_adds_nl_to_str_and_splits
    assert_equal ["abc\n", "xyz\n", ""], format.splitln("abc\nxyz")
  end

  def test_splitln_adds_linebreak_to_str_if_specified
    format.linebreak = "\r\n"
    assert_equal ["abc\n", "xyz\r\n", ""], format.splitln("abc\nxyz")
  end

  def test_splitln_renders_split_strings
    format.indent = '  '
    assert_equal ["  abc\n", "  xyz\n", ""], format.splitln("abc\nxyz")
  end

  #
  # strip test
  #

  def test_strip_sets_lstrip_rstrip
    format.strip = true
    assert_equal true, format.lstrip
    assert_equal true, format.rstrip

    format.strip = false
    assert_equal false, format.lstrip
    assert_equal false, format.rstrip
  end

  #
  # render test
  #

  def test_render_prefixes_line_with_indent
    format.indent = '..'
    assert_equal "..abc\n", format.render("abc\n")
  end

  def test_render_indents_using_indent_str_and_indent_level
    format.indent_str = '.'

    format.indent_level = 1
    assert_equal ".abc\n", format.render("abc\n")

    format.indent_level = 2
    assert_equal "..abc\n", format.render("abc\n")
  end

  def test_render_replaces_nl_with_eol
    format.eol = '.'
    assert_equal "abc.", format.render("abc\n")
  end

  def test_render_replaces_crnl_with_eol
    format.eol = '.'
    assert_equal "abc.", format.render("abc\r\n")
  end

  def test_render_replaces_tabs_with_tab
    format.tab = '.'
    assert_equal "a.b.c\n", format.render("a\tb\tc\n")
  end

  def test_render_tab_expansion_occurs_after_indent
    format.indent = "\t"
    format.tab = '.'
    assert_equal ".abc\n", format.render("abc\n")
  end

  def test_render_tab_expansion_applies_to_eol
    format.eol = "\t"
    format.tab = '.'
    assert_equal "abc.", format.render("abc\n")
  end

  def test_render_rstrips_to_eol_if_specified
    format.rstrip = true
    assert_equal "abc\n", format.render("abc  \n")
  end

  def test_render_lstrips_if_specified
    format.lstrip = true
    assert_equal "abc\n", format.render("  abc\n")
  end

  def test_render_lstrips_before_indent
    format.lstrip = true
    format.indent = "\t"
    assert_equal "\tabc\n", format.render("  abc\n")
  end
end
