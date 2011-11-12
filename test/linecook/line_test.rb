require 'test/unit'
require 'linecook/line'

class LineTest < Test::Unit::TestCase
  Line = Linecook::Line

  attr_reader :line

  def setup
    super
    @line = Line.new "abc\n"
  end

  def test_write
    line.write "xyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end

  def test_prepend
    line.prepend "xyz\n"
    assert_equal "xyz\nabc\n", line.to_s
  end

  def test_append
    line.append "xyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end

  def test_prefix
    line.prefix "xyz\n"
    assert_equal "xyz\nabc\n", line.to_s
  end

  def test_suffix
    line.suffix "xyz\n"
    assert_equal "abc\nxyz\n", line.to_s
  end

  def test_chain
    line.chain "xyz"
    assert_equal "abcxyz\n", line.to_s
  end

  def test_rewrites_together
    line.prepend "ABC\n"
    line.append "XYZ\n"
    line.chain "xyz\n"
    
    assert_equal "ABC\nabcxyz\nXYZ\n", line.to_s
  end

  def test_rewrites_on_separate_lines
    a = Line.new "abc\n"
    x = a.write "xyz\n"

    x.prepend "pre\n"
    a.append "POST\n"
    x.chain "chain\n"

    a.prepend "PRE\n"
    x.append "post\n"
    a.chain "CHAIN\n"

    assert_equal "PRE\nabcCHAIN\nPOST\npre\nxyzchain\npost\n", a.to_s
  end
end