require 'test/unit'
require 'linecook/document'
require 'logger'

class DocumentTest < Test::Unit::TestCase
  Document = Linecook::Document
  Line = Linecook::Line

  attr_accessor :doc

  def setup
    super
    @doc = Document.new()
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
  # insert test
  #

  def test_insert_writes_str_at_line
    doc.write "abc\nyz"
    doc.insert 1, "pqr\nx"

    assert_equal "abc\npqr\nxyz", doc.to_s
  end

  def test_insert_formats_inserted_content
    doc.set :indent => '..'
    doc.write "abc\nyz"
    doc.insert 1, "pqr\nx"

    assert_equal "..abc\n..pqr\n..xyz", doc.to_s
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
    doc.set :indent => '..'
    doc.write "a\n"
    doc.set :indent => '.'
    doc.write "b\n"
    doc.set :indent => ''
    doc.write "c\n"

    assert_equal "..a\n.b\nc\n", doc.to_s
  end

  def test_write_formats_multiple_lines
    doc.set :indent => '..'
    doc.write "abc\nxyz\n"

    assert_equal "..abc\n..xyz\n", doc.to_s
  end

  def test_write_formats_incomplete_lines
    doc.set :indent => '..'
    doc.write "abc\nxy"

    assert_equal "..abc\n..xy", doc.to_s
  end

  def test_write_preserves_line_referenence_for_incomplete_lines
    line = doc.write "abc\npq"
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
    doc.set :indent => '..'
    doc.writeln "abc"
    assert_equal "..abc\n", doc.to_s
  end

  #
  # set test
  #

  def test_set_sets_format_attrs
    assert_equal "", doc.format.indent
    doc.set :indent => ".."
    assert_equal "..", doc.format.indent
  end

  #
  # with test
  #

  def test_with_sets_format_attrs_for_block
    assert_equal "", doc.format.indent
    doc.with :indent => ".." do
      assert_equal "..", doc.format.indent
    end
    assert_equal "", doc.format.indent
  end

  #
  # indent test
  #

  def test_indent_increases_current_indent_by_one_for_block
    doc.writeln "a"
    doc.indent do
      doc.writeln "b"
      doc.indent do
        doc.writeln "c"
      end
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n  b\n    c\n  b\na\n", doc.to_s
  end

  def test_indent_increases_current_indent_by_n_if_specified
    doc.writeln "a"
    doc.indent(2) do
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n    b\na\n", doc.to_s
  end

  #
  # outdent test
  #

  def test_outdent_decreases_indent_to_zero
    doc.writeln "a"
    doc.indent do
      doc.writeln "b"
      doc.outdent do
        doc.writeln "c"
      end
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n  b\nc\n  b\na\n", doc.to_s
  end

  def test_outdent_decreases_indent_by_n_if_specified
    doc.writeln "a"
    doc.indent(2) do
      doc.writeln "b"
      doc.outdent(1) do
        doc.writeln "c"
      end
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n    b\n  c\n    b\na\n", doc.to_s
  end
end
