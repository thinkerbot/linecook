require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class LinecookTestTest < Test::Unit::TestCase
  include Linecook::Test
  
  #
  # script test
  #
  
  def test_script_builds_script_to_method_dir
    file('recipes/example.rb') {|io| io << "target << Array.new(attrs['n'], 'success').join(',')"}
    @cookbook = Linecook::Cookbook.init(method_dir)
    results = script('example', 'n' => 3)
    
    assert_equal path('scripts/example/example'), results['example']
    assert_equal "success,success,success", File.read(results['example'])
  end
  
  #
  # assert_output_equal test
  #

  def test_assert_output_equal_documentation
    assert_output_equal %q{
line one
line two
}, "line one\nline two\n"

    assert_output_equal %q{
  line one
  line two
}, "line one\nline two\n"

    assert_output_equal %q{
    line one
    line two
    }, "line one\nline two\n"
  end

  def test_assert_output_equal
    assert_output_equal %q{
    line one
      line two
    }, "line one\n  line two\n"

    assert_output_equal %q{
    line one
      line two}, "line one\n  line two"

    assert_output_equal %Q{  \t   \r
    line one
    line two
    }, "line one\nline two\n"

    assert_output_equal %q{
    
    
    }, "\n\n"

    assert_output_equal %q{
    
    }, "\n"

    assert_output_equal %Q{  \t   \r
    
    }, "\n"

    assert_output_equal %q{
    }, ""

    assert_output_equal %q{}, ""
    assert_output_equal %q{line one
line two
}, "line one\nline two\n"
  end

  #
  # assert_output_equal! test
  #

  def test_assert_output_equal_bang_does_not_strip_indentation
    assert_output_equal! %q{
    }, "\n    "
  end

  #
  # assert_alike test
  #

  def test_assert_alike_documentation
    assert_alike %q{
the time is: :...:
now!
}, "the time is: #{Time.now}\nnow!\n"

    assert_alike %q{
  the time is: :...:
  now!
}, "the time is: #{Time.now}\nnow!\n"

    assert_alike %q{
    the time is: :...:
    now!
    }, "the time is: #{Time.now}\nnow!\n"
  end

  def test_assert_alike
    assert_alike(/abc/, "...abc...")
  end

  def test_assert_alike_regexp_escapes_strings
    assert_alike "a:...:c", "...alot of random stuff toc..."
  end
end