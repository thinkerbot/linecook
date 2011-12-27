require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/document/cursor'

class CursorTest < Test::Unit::TestCase
  Cursor = Linecook::Document::Cursor
  Line = Linecook::Document::Line

  attr_accessor :cursor

  def setup
    super
    @cursor = Cursor.new
  end

  #
  # write test
  #

  def test_write_inserts_str_at_col
    line = Line.new
    line.write "ac"

    cursor = Cursor.new line, 1
    cursor.write "b"

    assert_equal "abc", line.content
  end

  def test_write_adds_new_lines_for_content_after_LF
    cursor.write "abc\n\nxyz"
    assert_equal ["abc\n", "\n", "xyz"], cursor.line.lines.map(&:content)
  end

  def test_write_advances_line_and_col
    cursor.write "a"
    assert_equal "a", cursor.line.content
    assert_equal 1, cursor.col

    cursor.write "bc\n\nxyz"
    assert_equal "xyz", cursor.line.content
    assert_equal 3, cursor.col

    assert_equal ["abc\n", "\n", "xyz"], cursor.line.lines.map(&:content)
  end

  def test_write_returns_self
    assert_equal cursor, cursor.write("abc")
  end

  #
  # before
  #

  def test_before_write
    cursor.write "abc"
    cursor.before.write "XYZ"
    assert_equal "abXYZc", cursor.line.content 
  end

  #
  # after
  #

  def test_after_write
    cursor.write "abc"
    cursor.after.write "XYZ"
    assert_equal "abcXYZ", cursor.line.content 
  end

  #
  # bol
  #

  def test_bol_write
    cursor.write "abc"
    cursor.bol.write "XYZ"
    assert_equal "XYZabc", cursor.line.content 
  end

  #
  # eol
  #

  def test_eol_write
    cursor.write "abc"
    cursor.col = 0
    cursor.eol.write "XYZ"
    assert_equal "abcXYZ", cursor.line.content 
  end

  #
  # prepend
  #

  def test_prepend_returns_cursor_to_new_line_before_line
    pre = cursor.prepend
    assert_equal cursor.line, pre.line.nex
  end

  def test_prepend_write
    cursor.write "abc"
    cursor.prepend.write "XYZ"
    assert_equal ["XYZ\n", "abc"], cursor.line.lines.map(&:content)
  end

  #
  # append
  #

  def test_append_returns_cursor_to_new_line_after_line
    nex = cursor.append
    assert_equal cursor.line, nex.line.pre
  end

  def test_append_write
    cursor.write "abc"
    cursor.append.write "XYZ"
    assert_equal ["abc\n", "XYZ"], cursor.line.lines.map(&:content)
  end
end