require 'test/unit'
require 'linecook/format'

class FormatTest < Test::Unit::TestCase
  Format = Linecook::Format

  attr_accessor :format

  def setup
    super
    @format = Format.new
  end

  #
  # indent= test
  #

  def test_set_indent_sets_indent_str_and_indent_level
    format.indent = "  "
    assert_equal "  ", format.indent_str
    assert_equal 1, format.indent_level
    assert_equal "  ", format.indent

    format.indent_level = 2
    assert_equal "    ", format.indent

    format.indent = ".."
    assert_equal "..", format.indent_str
    assert_equal 1, format.indent_level
    assert_equal "..", format.indent
  end

  #
  # strip= test
  #

  def test_set_strip_sets_lstrip_rstrip
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

  def test_render_preserves_nl_if_eol_is_nil
    assert_equal "abc\n", format.render("abc\n")
  end

  def test_render_preserves_crnl_if_eol_is_nil
    assert_equal "abc\r\n", format.render("abc\r\n")
  end

  def test_render_does_not_add_eol_if_str_does_not_end_with_linebreak
    format.eol = '.'
    assert_equal "abc", format.render("abc")
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
