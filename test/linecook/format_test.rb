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

  def test_render_appends_indent_to_nl
    format.indent = '..'
    assert_equal "\n..abc\n..xyz\n..", format.render("\nabc\nxyz\n")
  end

  def test_render_prefixes_with_indent_if_first
    format.indent = '..'
    assert_equal "..abc", format.render("abc", true)
  end

  def test_render_does_not_append_indent_if_last
    format.indent = '..'
    assert_equal "abc\n", format.render("abc\n", false, true)
  end

  def test_render_replaces_nl_with_eol
    format.eol = '.'
    assert_equal ".abc.xyz.", format.render("\nabc\nxyz\n")
  end

  def test_render_replaces_crnl_with_eol
    format.eol = '.'
    assert_equal ".abc.xyz.", format.render("\r\nabc\r\nxyz\r\n")
  end

  def test_render_preserves_nl_if_eol_is_nil
    assert_equal "abc\n", format.render("abc\n")
  end

  def test_render_preserves_crnl_if_eol_is_nil
    assert_equal "abc\r\n", format.render("abc\r\n")
  end

  def test_render_does_not_append_eol
    format.eol = '.'
    assert_equal "abc", format.render("abc")
  end

  def test_render_applies_indent_before_eol_tr
    format.eol = ":\n:"
    format.indent = '..'
    assert_equal "abc:\n:..xyz", format.render("abc\nxyz")
  end

  def test_render_replaces_tabs_with_tab
    format.tab = '.'
    assert_equal ".abc.xyz.", format.render("\tabc\txyz\t")
  end

  def test_render_does_not_replace_tabs_for_nil_tab
    format.tab = nil
    assert_equal "\tabc\txyz\t", format.render("\tabc\txyz\t")
  end

  def test_render_replaces_tabs_after_indent
    format.indent = "\t"
    format.tab = '.'
    assert_equal "abc\n.xyz", format.render("abc\nxyz")
  end

  def test_render_replaces_tabs_after_eol_tr
    format.eol = "\t"
    format.tab = '.'
    assert_equal "abc.xyz", format.render("abc\nxyz")
  end

  def test_render_lstrips_after_eol_if_specified
    format.lstrip = true
    assert_equal "  \nabc  \nxyz  \n", format.render("  \n  abc  \n  xyz  \n  ")
  end

  def test_render_lstrips_without_eol_if_first
    format.lstrip = true
    assert_equal "abc", format.render("  abc", true)
  end

  def test_render_lstrip_preserves_leading_eol_if_first
    format.lstrip = true
    assert_equal "\n\nabc", format.render("  \n  \n  abc", true)
  end

  def test_render_lstrips_before_indent
    format.lstrip = true
    format.indent = "\t"
    assert_equal "abc\n\txyz\n\t", format.render("abc\n  xyz\n  ")
  end

  def test_render_rstrips_to_eol_if_specified
    format.rstrip = true
    assert_equal "\n  abc\n  xyz\n  ", format.render("  \n  abc  \n  xyz  \n  ")
  end

  def test_render_rstrips_without_eol_if_last
    format.rstrip = true
    assert_equal "abc", format.render("abc  ", false, true)
  end

  def test_render_rstrip_preserves_trailing_eol_if_last
    format.rstrip = true
    assert_equal "abc\n\n", format.render("abc  \n  \n  ", false, true)
  end
end
