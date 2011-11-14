require 'test/unit'
require 'linecook/document'

class DocumentTest < Test::Unit::TestCase
  Document = Linecook::Document

  attr_accessor :doc

  def setup
    super
    @doc = Document.new
  end

  #
  # write test
  #

  def test_write_adds_str_to_doc
    doc.write "line\n"
    assert_equal "line\n", doc.to_s
  end

  def test_write_reformats_str_with_indent
    doc.indent = '..'
    doc.write "a\n"
    doc.indent = '.'
    doc.write "b\n"
    doc.indent = ''
    doc.write "c\n"

    assert_equal "..a\n.b\nc\n", doc.to_s
  end

  def test_write_reformats_str_with_eol
    doc.eol = "."
    doc.write "a\n"
    doc.write "b\n"
    doc.write "c\n"

    assert_equal "a.b.c.", doc.to_s
  end

  def test_write_continues_last_line_until_linebreak
    doc.write "a"
    doc.write "b"
    doc.write "c\n"
    doc.write "x"
    doc.write "y"
    doc.write "z\n"

    assert_equal "abc\nxyz\n", doc.to_s
  end

  def test_write_rewrites_linebreak_to_eol
    doc.linebreak = '.'
    doc.eol = ';'

    doc.write "a;"
    doc.write "b;"
    doc.write "c."
    doc.write "x;"
    doc.write "y;"
    doc.write "z."

    assert_equal "a;b;c;x;y;z;", doc.to_s
  end

  def test_write_rstrips_at_linebreak_if_specified
    doc.rstrip = true
    doc.write "a "
    doc.write "b "
    doc.write "c \nxyz \n"

    assert_equal "a b c\nxyz\n", doc.to_s
  end

  def test_write_applies_indent_after_rstrip
    doc.rstrip = true
    doc.indent = "  "
    doc.write "a "
    doc.write "b "
    doc.write "c \nxyz \n"

    assert_equal "  a b c\n  xyz\n", doc.to_s
  end

  def test_write_lstrips_at_linebreak_if_specified
    doc.lstrip = true
    doc.write " a"
    doc.write " b"
    doc.write " c\n xyz\n"

    assert_equal "a b c\nxyz\n", doc.to_s
  end

  def test_write_applies_indent_after_lstrip
    doc.lstrip = true
    doc.indent = "  "
    doc.write " a"
    doc.write " b"
    doc.write " c\n xyz\n"

    assert_equal "  a b c\n  xyz\n", doc.to_s
  end

  def test_write_reformats_multiple_lines
    doc.indent = "  "
    doc.eol    = "."
    doc.linebreak = "\n"
    doc.write "abc\nxyz\n"

    assert_equal "  abc.  xyz", doc.to_s
  end

  #
  # line usage tests
  #

  def test_write_returns_line_for_last_line_written
    line = doc.write "...\nabc\n"
    doc.write "...\n"

    assert_equal "abc\n", line.to_s

    line.prepend "ABC\n"
    line.append "XYZ\n"
    line.chain "xyz\n"

    assert_equal "...\nABC\nabcxyz\nXYZ\n...", doc.to_s
  end

  def test_line_uses_format_settings_at_time_of_creation
    doc.write "...\n"
    doc.indent = "  "

    line = doc.write "abc\n"

    doc.indent = ""
    doc.write "...\n"

    line.prepend "ABC\n"
    line.append "XYZ\n"
    line.chain "xyz\n"

    assert_equal "...\n  ABC\n  abcxyz\n  XYZ\n...", doc.to_s
  end

  def test_prepend_is_formatted
    doc.indent = "  "

    line = doc.write "abc\n"
    line.prepend "ABC\n"

    assert_equal "  ABC\n  abc\n", doc.to_s
  end

  def test_append_is_formatted
    doc.indent = "  "

    line = doc.write "abc\n"
    line.append "XYZ\n"

    assert_equal "  abc\n  XYZ\n", doc.to_s
  end

  def test_chain_is_not_formatted
    doc.rstrip = true

    line = doc.write "abc \n"
    assert_equal "abc\n", doc.to_s

    line.chain "xyz \n"

    assert_equal "abcxyz \n", doc.to_s
  end

  def test_chain_to_an_incomplete_line_completes_the_line
    line = doc.write "abc"
    line.chain "xyz"

    assert_equal "abcxyz\n", doc.to_s
  end

  #
  # writeln test
  #

  def test_writeln_adds_str_and_eol_to_doc
    doc.eol = '.'
    doc.writeln "line"
    assert_equal "line.", doc.to_s
  end

  def test_writeln_accepts_multiple_input_lines
    doc.writeln "abc\nxyz\n"
    assert_equal "abc\nxyz\n\n", doc.to_s
  end

  def test_writeln_continues_last_line
    doc.write "a"
    doc.write "b"
    doc.writeln "c"
    doc.write "x"
    doc.write "y"
    doc.writeln "z"

    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # writelit test
  #

  def test_writelit_writes_string_without_processing
    doc.indent = ""
    doc.writeln "abc\nxyz\n"
    assert_equal "abc\nxyz\n", doc.to_s
  end

  def test_writelit_returns_line_for_full_literal
    line = doc.writeln "abc\nxyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end
end