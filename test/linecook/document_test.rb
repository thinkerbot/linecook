require 'test/unit'
require 'linecook/document'
require 'logger'

class DocumentTest < Test::Unit::TestCase
  Document = Linecook::Document
  Format = Linecook::Format
  Line = Linecook::Line

  attr_accessor :doc
  attr_accessor :format

  def setup
    super
    logger = $DEBUG ? Logger.new(STDOUT) : nil
    puts if logger
    @format = Format.new(logger)
    @doc = Document.new([], format)
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
  # line test
  #

  def test_line_returns_line_at_index
    doc.write "abc\npqr\nxy"
    assert_equal "abc\n", doc.line(0).to_s
    assert_equal "pqr\n", doc.line(1).to_s
    assert_equal "xy", doc.line(2).to_s
  end

  def test_line_returns_last_line_by_default
    doc.write "abc\npqr\nxy"
    assert_equal "xy", doc.line.to_s
  end

  #
  # write test
  #

  def test_write_writes_to_doc
    doc.write "a"
    doc.write "b"
    doc.write "c\n"
    doc.write "x"
    doc.write "y"
    doc.write "z\n"

    assert_equal "abc\nxyz\n", doc.to_s
  end

  def test_write_formats_lines_according_to_format
    format.indent = '..'
    doc.write "a\n"
    format.indent = '.'
    doc.write "b\n"
    format.indent = ''
    doc.write "c\n"

    assert_equal "..a\n.b\nc\n", doc.to_s
  end

  def test_write_formats_multiple_lines
    format.indent = '..'
    doc.write "abc\nxyz\n"

    assert_equal "..abc\n..xyz\n", doc.to_s
  end

  def test_write_formats_incomplete_lines
    format.indent = '..'
    doc.write "abc\nxy"

    assert_equal "..abc\n..xy", doc.to_s
  end

  def test_write_preserves_line_referenence_for_incomplete_lines
    doc.write "abc\npq"
    line = doc.line(-1)

    assert_equal "pq", line.to_s

    doc.write "r\nxy"
    assert_equal "pqr\n", line.to_s

    assert_equal "abc\npqr\nxy", doc.to_s
  end

  def test_write_returns_line
    a = doc.write "abc\n"
    assert_equal true, Line === a
    assert_equal "abc\n", a.content
  end

  #
  # writeln test
  #

  def test_writeln_adds_linebreak_and_writes_to_doc
    format.indent = '..'
    doc.writeln "abc"
    assert_equal "..abc\n", doc.to_s
  end
end
