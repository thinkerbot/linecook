require File.expand_path('../../test_helper', __FILE__)
require 'linecook/document'

class DocumentTest < Test::Unit::TestCase
  Document = Linecook::Document
  Line = Linecook::Line

  attr_accessor :doc

  def setup
    super
    @doc = Document.new
  end

  def abc_doc(&format)
    a = Line.new format, nil, nil
    b = Line.new format, a,   nil
    c = Line.new format, b,   nil

    [a,b,c,Document.new(a)]
  end

  #
  # initialize test
  #

  def test_initialize_sets_first
    line = Line.new
    doc = Document.new line
    assert_equal line, doc.first
  end

  #
  # first test
  #

  def test_first_returns_first_line_in_lines
    current = doc.first
    assert_equal [current], doc.lines
  end

  def test_first_returns_first_line_in_lines_after_prepend
    current = doc.first
    pre = doc.first.prepend

    assert_equal [pre, current], doc.lines
    assert_equal pre, doc.first
  end

  #
  # last test
  #

  def test_last_returns_last_line_in_lines
    current = doc.last
    assert_equal [current], doc.lines
  end

  def test_last_returns_last_line_in_lines_after_prepend
    current = doc.last
    nex = doc.last.append

    assert_equal [current, nex], doc.lines
    assert_equal nex, doc.last
  end

  #
  # lines test
  #

  def test_lines_returns_array_of_lines_in_self
    a, b, c, doc = abc_doc
    assert_equal [a, b, c], doc.lines
  end

  #
  # each test
  #

  def test_each_calls_block_with_each_line
    a, b, c, doc = abc_doc

    lines = []
    doc.each do |line|
      lines << line
    end

    assert_equal [a, b, c], lines
  end

  #
  # reverse_each test
  #

  def test_reverse_each_calls_block_with_each_line_in_reverse
    a, b, c, doc = abc_doc

    lines = []
    doc.reverse_each do |line|
      lines << line
    end

    assert_equal [c, b, a], lines
  end

  #
  # length test
  #

  def test_length_returns_sum_of_line_lengths
    doc.write "abc\n"
    assert_equal 4, doc.length
    doc.write "xyz\n"
    assert_equal 8, doc.length
  end

  #
  # at test
  #

  def test_at_returns_line_and_col_at_position
    a = doc.write "abc\n"
    b = doc.write "xyz\n"

    assert a != b
    assert_equal [a, 0], doc.at(0)
    assert_equal [a, 3], doc.at(3)
    assert_equal [b, 0], doc.at(4)
  end

  def test_at_allows_negative_pos_from_end
    a = doc.write "abc\n"
    b = doc.write "xyz\n"

    assert a != b
    assert_equal [b, 3], doc.at(-1)
    assert_equal [b, 0], doc.at(-4)
    assert_equal [a, 3], doc.at(-5)
  end

  def test_at_returns_nil_for_pos_out_of_range
    assert_equal 0, doc.length
    assert_equal nil, doc.at(100)
    assert_equal nil, doc.at(-100)
  end

  #
  # line test
  #

  def test_line_returns_line_at_index
    a, b, c, doc = abc_doc

    assert_equal a, doc.line(0)
    assert_equal c, doc.line(2)
  end

  def test_line_allows_negative_index_from_end
    a, b, c, doc = abc_doc

    assert_equal c, doc.line(-1)
    assert_equal a, doc.line(-3)
  end

  def test_line_returns_nil_for_index_out_of_range
    assert_equal 1, doc.count
    assert_equal nil, doc.line(100)
    assert_equal nil, doc.line(-100)
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

  def test_write_returns_last
    line = doc.write("abc\n")
    assert_equal doc.last, line
    assert_equal "abc\n", doc.to_s

    line = doc.write("xy")
    assert_equal doc.last, line
    assert_equal "abc\nxy", doc.to_s

    line = doc.write("z\n")
    assert_equal doc.last, line
    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # writeln test
  #

  def test_writeln_adds_linebreak_and_writes_to_doc
    doc.writeln "abc"
    assert_equal "abc\n", doc.to_s
  end

  def test_writeln_returns_last
    line = doc.writeln("abc")
    assert_equal doc.last, line
    assert_equal "abc\n", doc.to_s

    line = doc.writeln("xyz")
    assert_equal doc.last, line
    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # insert test
  #

  def test_insert_writes_str_at_pos
    doc.write "abc\nyz"
    doc.insert 4, "pqr\nx"

    assert_equal "abc\npqr\nxyz", doc.to_s
  end

  def test_insert_accepts_negative_pos
    doc.write "abc\nyz"
    doc.insert(-2, "pqr\nx")

    assert_equal "abc\npqr\nxyz", doc.to_s
  end

  def test_insert_raises_range_error_for_pos_out_of_range
    err = assert_raises(RangeError) { doc.insert(100, "abc") }
    assert_equal "pos out of range: 100", err.message
    err = assert_raises(RangeError) { doc.insert(-100, "xyz") }
    assert_equal "pos out of range: -100", err.message

    assert_equal "", doc.to_s
  end

  def test_insert_returns_the_line_that_recieves_the_new_content
    doc.write "abc\nxyz"
    line = doc.insert 3, "\npqr"
    assert_equal "abc\n", line.to_s
  end

  def test_insert_formats_inserted_content
    doc.set :indent => '..'
    doc.write "abc\nyz"
    doc.insert 4, "pqr\nx"

    assert_equal "..abc\n..pqr\n..xyz", doc.to_s
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

  def test_indent_sets_indent_if_string_is_specified
    doc.writeln "a"
    doc.indent('..') do
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n..b\na\n", doc.to_s
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

  def test_outdent_changes_indent_by_n_if_specified
    doc.writeln "a"
    doc.indent(2) do
      doc.writeln "b"
      doc.outdent(-1) do
        doc.writeln "c"
      end
      doc.writeln "b"
    end
    doc.writeln "a"

    assert_equal "a\n    b\n  c\n    b\na\n", doc.to_s
  end

  #
  # clear test
  #

  def test_clear_clears_all_content_preserving_format
    doc.set :indent => '..'
    doc.write "abc\n"
    doc.write "pqr\n"
    doc.clear
    doc.write "xyz\n"

    assert_equal "..xyz\n", doc.to_s
  end
end
