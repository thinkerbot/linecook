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
end
