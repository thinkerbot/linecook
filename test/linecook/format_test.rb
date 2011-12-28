require File.expand_path('../../test_helper', __FILE__)
require 'linecook/format'

class FormatTest < Test::Unit::TestCase
  Format = Linecook::Format

  attr_accessor :format

  def setup
    super
    @format = Format.new :eol => nil
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
  # set test
  #

  def test_set_raises_error_for_unknown_attribute
    err = assert_raises(NoMethodError) { format.set :unknown => :off }
    assert_match(/undefined method `unknown='/, err.message)
  end

  #
  # indent_level= test
  #

  def test_set_indent_level_raises_error_for_negative_level
    err = assert_raises(RuntimeError) { format.indent_level = -1 }
    assert_equal "indent level cannot be set to negative value: -1", err.message
  end

  #
  # indent= test
  #

  def test_set_indent_sets_indent_str_and_indent_level
    assert_equal "  ", format.indent_str
    assert_equal 0, format.indent_level

    format.indent = ".."

    assert_equal "..", format.indent_str
    assert_equal 1, format.indent_level
  end

  def test_set_indent_offsets_indent_level_by_n
    assert_equal 0, format.indent_level

    format.indent = 2
    assert_equal 2, format.indent_level

    format.indent = 2
    assert_equal 4, format.indent_level
  end

  def test_set_indent_sets_indent_level_to_zero_for_nil
    format.indent_level = 2
    format.indent = nil
    assert_equal 0, format.indent_level
  end

  #
  # indent
  #

  def test_indent_equals_indent_str_times_indent_level
    format.indent_str = '.'
    format.indent_level = 1
    assert_equal ".", format.indent

    format.indent_level = 2
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
  # with test
  #

  def test_with_returns_dup_with_new_attrs
    a = format.with :indent => "..", :eol => "\r\n"
    assert_equal "..",   a.indent
    assert_equal "\r\n", a.eol

    b = a.with :indent => ""
    assert_equal "",     b.indent
    assert_equal "\r\n", b.eol
  end

  #
  # render test
  #

  def test_render_prefixes_line_with_indent
    format.indent = '..'
    assert_equal "..abc", format.render("abc")
  end

  def test_render_adds_eol
    format.eol = '.'
    assert_equal "abc.", format.render("abc")
  end

  def test_render_expands_tabs_with_tab
    format.tab = '.'
    assert_equal "a.b.c", format.render("a\tb\tc")
  end

  def test_render_expands_tabs_after_adding_indent
    format.indent = "\t"
    format.tab = '.'
    assert_equal ".abc", format.render("abc")
  end

  def test_render_expands_tabs_after_adding_eol
    format.eol = "\t"
    format.tab = '.'
    assert_equal "abc.", format.render("abc")
  end

  def test_render_rstrips_if_specified
    format.rstrip = true
    assert_equal "abc", format.render("abc  ")
  end

  def test_render_rstrips_before_adding_eol
    format.eol = "\n"
    format.rstrip = true
    assert_equal "abc\n", format.render("abc  ")
  end

  def test_render_lstrips_if_specified
    format.lstrip = true
    assert_equal "abc", format.render("  abc")
  end

  def test_render_lstrips_before_indent
    format.lstrip = true
    format.indent = "\t"
    assert_equal "\tabc", format.render("  abc")
  end

  def test_render_returns_empty_str_if_empty_content_and_last
    format.indent = ".."
    format.eol = "."
    assert_equal "", format.render("", false, true)
  end
end
