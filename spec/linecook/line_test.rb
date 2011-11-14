require 'test/unit'
require 'linecook/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Line

  attr_reader :line

  def setup
    super
    @line = Line.new "abc\n"
  end

  def test_prepend_adds_lines_before_self
    line.prepend "xyz\n"
    assert_equal "xyz\nabc\n", line.to_s
  end

  def test_append_adds_lines_after_self
    line.append "xyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end

  def test_prefix_prepends_content_to_current
    line.prefix "xyz\n"
    assert_equal "xyz\nabc\n", line.to_s
  end

  def test_suffix_appends_content_to_current
    line.suffix "xyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end

  def test_chain_appends_content_before_eol
    line.chain "xyz"
    assert_equal "abcxyz\n", line.to_s
  end

  def test_line_preserves_state
    x = a.append "xyz\n"

    x.prepend "pre\n"
    a.append "POST\n"
    x.chain "chain\n"

    a.prepend "PRE\n"
    x.append "post\n"
    a.chain "CHAIN\n"

    assert_equal "PRE\nabcCHAIN\nPOST\npre\nxyzchain\npost\n", a.to_s
  end
end