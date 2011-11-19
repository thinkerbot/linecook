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
  # initialize test
  #

  def test_initialize_sets_attrs
    format = Format.new :indent => "..", :eol => "\r\n"
    assert_equal "..",   format.indent
    assert_equal "\r\n", format.eol
  end

  #
  # merge test
  #

  def test_merge_returns_dup_with_new_attrs
    a = format.merge :indent => "..", :eol => "\r\n"
    assert_equal "..",   a.indent
    assert_equal "\r\n", a.eol

    b = a.merge :indent => ""
    assert_equal "",     b.indent
    assert_equal "\r\n", b.eol
  end

  #
  # merge! test
  #

  def test_merge_bang_sets_attrs_on_self
    assert_equal "",  format.indent
    assert_equal nil, format.eol

    format.merge! :indent => "..", :eol => "\r\n"

    assert_equal "..",   format.indent
    assert_equal "\r\n", format.eol
  end

  def test_merge_indent_sets_indent_str_and_indent_level
    format.merge! :indent => "  "
    assert_equal "  ", format.indent_str
    assert_equal 1, format.indent_level
    assert_equal "  ", format.indent

    format.merge! :indent_level => 2
    assert_equal "    ", format.indent

    format.merge! :indent => ".."
    assert_equal "..", format.indent_str
    assert_equal 1, format.indent_level
    assert_equal "..", format.indent
  end

  def test_merge_strip_sets_lstrip_rstrip
    format.merge! :strip => true
    assert_equal true, format.lstrip
    assert_equal true, format.rstrip

    format.merge! :strip => false
    assert_equal false, format.lstrip
    assert_equal false, format.rstrip
  end

  #
  # render test
  #

  def test_render_prefixes_line_with_indent
    format.merge! :indent => '..'
    assert_equal "..abc\n", format.render("abc\n")
  end

  def test_render_indents_using_indent_str_and_indent_level
    format.merge! :indent_str => '.'

    format.merge! :indent_level => 1
    assert_equal ".abc\n", format.render("abc\n")

    format.merge! :indent_level => 2
    assert_equal "..abc\n", format.render("abc\n")
  end

  def test_render_replaces_nl_with_eol
    format.merge! :eol => '.'
    assert_equal "abc.", format.render("abc\n")
  end

  def test_render_replaces_crnl_with_eol
    format.merge! :eol => '.'
    assert_equal "abc.", format.render("abc\r\n")
  end

  def test_render_preserves_nl_if_eol_is_nil
    assert_equal "abc\n", format.render("abc\n")
  end

  def test_render_preserves_crnl_if_eol_is_nil
    assert_equal "abc\r\n", format.render("abc\r\n")
  end

  def test_render_does_not_add_eol_if_str_does_not_end_with_linebreak
    format.merge! :eol => '.'
    assert_equal "abc", format.render("abc")
  end

  def test_render_replaces_tabs_with_tab
    format.merge! :tab => '.'
    assert_equal "a.b.c\n", format.render("a\tb\tc\n")
  end

  def test_render_tab_expansion_occurs_after_indent
    format.merge! :indent => "\t"
    format.merge! :tab => '.'
    assert_equal ".abc\n", format.render("abc\n")
  end

  def test_render_tab_expansion_applies_to_eol
    format.merge! :eol => "\t"
    format.merge! :tab => '.'
    assert_equal "abc.", format.render("abc\n")
  end

  def test_render_rstrips_to_eol_if_specified
    format.merge! :rstrip => true
    assert_equal "abc\n", format.render("abc  \n")
  end

  def test_render_lstrips_if_specified
    format.merge! :lstrip => true
    assert_equal "abc\n", format.render("  abc\n")
  end

  def test_render_lstrips_before_indent
    format.merge! :lstrip => true
    format.merge! :indent => "\t"
    assert_equal "\tabc\n", format.render("  abc\n")
  end
end
