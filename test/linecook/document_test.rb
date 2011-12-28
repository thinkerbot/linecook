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
  # chain? test
  #

  def test_chain_check_returns_true_if_current_line_is_not_empty
    assert_equal false, doc.chain?
    doc.current_line.write "a"
    assert_equal true, doc.chain?
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

  #
  # prepend test
  #

  def test_prepend_prepends_a_line_to_head_and_writes_str
    a, b, c, doc = abc_doc
    a.write "a"
    b.write "b"
    c.write "c"
    doc.set_marks(b)

    doc.prepend("XYZ")
    assert_equal "aXYZbc", doc.to_s
  end

  def test_prepend_does_not_move_head
    doc.write "xyz"
    doc.prepend "abc\npqr"
    assert_equal "xyz", doc.head.to_s
  end

  #
  # append test
  #

  def test_append_appends_a_line_to_tail_and_writes_str
    a, b, c, doc = abc_doc
    a.write "a"
    b.write "b"
    c.write "c"
    doc.set_marks(b)

    doc.append("XYZ")
    assert_equal "abXYZc", doc.to_s
  end

  def test_append_advances_tail_to_last_line_appended
    doc.write "abc"
    doc.append "pqr\nxyz"
    assert_equal "xyz", doc.tail.to_s
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

  def test_cut_returns_nil_for_index_out_of_range
    a, b, c, doc = abc_doc
    assert_equal nil, doc.cut(100)
    assert_equal nil, doc.cut(-100)
    assert_equal [a, b, c], doc.lines
  end

  def test_cut_returns_nil_for_zero_length
    a, b, c, doc = abc_doc
    assert_equal nil, doc.cut(1, 0)
    assert_equal [a, b, c], doc.lines
  end

  def test_cut_returns_nil_for_negative_length
    a, b, c, doc = abc_doc
    assert_equal nil, doc.cut(1, -1)
    assert_equal [a, b, c], doc.lines
  end

  #
  # ltrim test
  #

  def test_ltrim_removes_empty_lines_from_head
    doc.write "\n\n\nabc\nxyz\n"
    doc.ltrim
    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # rtrim test
  #

  def test_rtrim_removes_empty_lines_from_tail
    doc.write "abc\nxyz\n\n\n"
    doc.rtrim
    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # trim test
  #

  def test_trim_removes_empty_lines_from_head_and_tail
    doc.write "\n\n\nabc\nxyz\n\n\n"
    doc.trim
    assert_equal "abc\nxyz\n", doc.to_s
  end

  #
  # set test
  #

  def test_set_sets_format_attrs
    assert_equal "", doc.format.indent
    doc.set :indent => ".."
    assert_equal "..", doc.format.indent
  end

  def test_set_completes_line_before_changing_format
    doc.write 'abc'
    doc.set :indent => ".."
    doc.write 'xyz'
    assert_equal "abc\n..xyz\n", doc.to_s
  end

  #
  # set! test
  #

  def test_set_bang_changes_format_for_current_line
    doc.write 'abc'
    doc.set!(:indent => "..")
    doc.write 'xyz'
    assert_equal "..abcxyz\n", doc.to_s
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

  def test_with_completes_lines_before_and_after_block
    doc.write 'abc'
    doc.with :indent => ".." do
      doc.write 'xyz'
    end
    assert_equal "abc\n..xyz\n", doc.to_s
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

  #
  # to_s test
  #

  def test_new_documents_are_empty
    assert_equal "", doc.to_s
  end
end
