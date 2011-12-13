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

  class WriteToInput
    def write_to(line)
      line.write "abc"
    end
  end

  def test_write_delegates_to_write_to_method_on_input_if_possible
    doc.write WriteToInput.new
    assert_equal "abc", doc.to_s
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
  # chain test
  #

  def test_chain_chains_to_last
    doc.write "ab\n"
    doc.chain "c"

    assert_equal "abc\n", doc.to_s
  end

  def test_chain_returns_last
    line = doc.chain("ab\n")
    assert_equal doc.last, line
    assert_equal "ab\n", doc.to_s

    line = doc.chain("c\nxyz")
    assert_equal doc.last, line
    assert_equal "abc\nxyz\n", doc.to_s
  end

  class ChainToInput
    def chain_to(line)
      line.chain "xyz"
    end
  end

  def test_chain_delegates_to_chain_to_method_on_input_if_possible
    doc.write "abc\n"
    doc.chain ChainToInput.new
    assert_equal "abcxyz\n", doc.to_s
  end

  #
  # cut test
  #

  def test_cut_removes_and_return_line_at_index
    a, b, c, doc = abc_doc
    assert_equal b, doc.cut(1)
    assert_equal [a, c], doc.lines
  end

  def test_cut_removes_n_lines
    a, b, c, doc = abc_doc
    assert_equal a, doc.cut(0,2)
    assert_equal [a, b], a.lines
    assert_equal [c], doc.lines
  end

  def test_cut_allows_cut_to_last
    a, b, c, doc = abc_doc
    assert_equal b, doc.cut(1, 3)
    assert_equal [b, c], b.lines
    assert_equal [a], doc.lines
  end

  def test_cut_allows_removal_of_all_lines
    a, b, c, doc = abc_doc
    assert_equal a, doc.cut(0,3)
    assert_equal [a, b, c], a.lines
    assert_equal [doc.first], doc.lines
  end

  def test_cut_allows_negative_index_from_end
    a, b, c, doc = abc_doc
    assert_equal c, doc.cut(-1)
    assert_equal [a, b], doc.lines
  end

  def test_cut_allows_negative_length_to_count_backwards
    a, b, c, doc = abc_doc
    assert_equal a, doc.cut(1, -1)
    assert_equal [b, c], doc.lines
  end

  def test_cut_with_allows_negative_length_to_cut_to_head
    a, b, c, doc = abc_doc
    a.write 'a'
    b.write 'b'
    c.write 'c'
    assert_equal a, doc.cut(2, -3)
    assert_equal [a, b], a.lines
    assert_equal [c], doc.lines
  end

  def test_cut_returns_nil_for_index_out_of_range
    a, b, c, doc = abc_doc
    assert_equal nil, doc.cut(100)
    assert_equal nil, doc.cut(-100)
  end

  def test_cut_returns_nil_for_zero_length
    a, b, c, doc = abc_doc
    assert_equal nil, doc.cut(1, 0)
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

  def test_clear_returns_self
    assert_equal doc, doc.clear
  end
end
