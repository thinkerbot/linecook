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
    format.eol = "."
    assert_equal "abc.", format.render("abc\n")
  end

  def test_render_replaces_crnl_with_eol
    format.eol = "."
    assert_equal "abc.", format.render("abc\r\n")
  end

  def test_render_replaces_tabs_with_tab
    format.tab = "."
    assert_equal "a.b.c\n", format.render("a\tb\tc\n")
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
