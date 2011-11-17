require 'test/unit'
require 'linecook/document'
require 'logger'

class DocumentTest < Test::Unit::TestCase
  Document = Linecook::Document

  attr_accessor :doc

  def setup
    super
    logger = $DEBUG ? Logger.new(STDOUT) : nil
    puts if logger
    @doc = Document.new([], logger)
  end

  #
  # pos test
  #

  def test_pos_returns_index_for_content_in_lines
    a, b, c = %w{a b c}
    doc.lines.concat [a, b, c]

    assert_equal 0, doc.pos(a)
    assert_equal 1, doc.pos(b)
    assert_equal 2, doc.pos(c)
  end

  def test_pos_requires_equal_equality
    a1, a2, a3 = %w{a a, a}
    doc.lines.concat [a1, a2, a3]

    assert_equal 0, doc.pos(a1)
    assert_equal 1, doc.pos(a2)
    assert_equal 2, doc.pos(a3)
  end

  def test_pos_returns_nil_if_lines_does_not_contain_content
    assert_equal nil, doc.pos("unknown")
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

  def test_indent_is_determined_by_indent_str_and_indent_level_unless_set
    doc.indent_str = '.'
    doc.indent_level = 2
    doc.write "a\n"
    doc.indent_level = 1
    doc.write "b\n"
    doc.indent_level = 0
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

  def test_write_replaces_tabs_with_tab
    doc.tab = "."
    doc.write "a\tb\tc\n"

    assert_equal "a.b.c\n", doc.to_s
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
    doc.linebreak = /\./
    doc.eol = ';'

    doc.write "a;"
    doc.write "b;"
    doc.write "c."
    doc.write "x;"
    doc.write "y;"
    doc.write "z."

    assert_equal "a;b;c;x;y;z;", doc.to_s
  end

  def test_write_rstrips_at_if_specified
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
    doc.linebreak = /\n/
    doc.write "abc\nxyz\n"

    assert_equal "  abc.  xyz.", doc.to_s
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
    doc.writelit "abc\nxyz\n"
    assert_equal "abc\nxyz\n", doc.to_s
  end

  def test_writelit_returns_line_for_full_literal
    line = doc.writelit "abc\nxyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end
end
