require File.expand_path('../../../../test_helper', __FILE__)
require 'linecook/os/posix'
require 'linecook/test'

class PosixUtilsTest < Test::Unit::TestCase
  include Linecook::Test
  include Linecook::Os::Posix::Utils

  #
  # command_str test
  #

  def test_command_str_formats_a_command
    cmd  = command_str('command', 'one', 'two', 'three', 'a' => true, 'b' => true, 'c' => true)
    assert_equal 'command -a -b -c "one" "two" "three"', cmd
  end

  def test_command_str_does_not_quote_quoted_args
    assert_equal %{command_name "one" 'two'}, command_str('command_name', '"one"', "'two'")
  end

  def test_command_str_quotes_partially_quoted_args
    assert_equal %{command_name "'one" "two'" "th'ree"}, command_str('command_name', "'one", "two'", "th'ree")
  end

  def test_command_str_skips_nil_args
    cmd = command_str 'which', nil, 'name'
    assert_equal 'which "name"', cmd
  end

  #
  # option? test
  #

  def test_option_check_returns_true_if_arg_begins_with_plus_or_minus
    assert_equal true,  option?("--option")
    assert_equal true,  option?("-o")
    assert_equal true,  option?("+o")
    assert_equal false, option?("arg")
  end

  #
  # options_str test
  #

  def test_options_str_formats_key_value_options_to_options_array
    assert_equal ['--key "value"'], options_str('--key' => '"value"')
  end

  def test_options_str_quotes_values
    assert_equal ['--key "value"'], options_str('--key' => 'value')
  end

  def test_options_str_stringifies_values
    assert_equal ['--key "value"'], options_str('--key' => :value)
  end

  def test_options_str_omits_value_for_true
    assert_equal ['--key'], options_str('--key' => true)
  end

  def test_options_str_omits_options_with_false_or_nil_values
    assert_equal [], options_str('--key' => false)
    assert_equal [], options_str('--key' => nil)
  end

  def test_options_str_guesses_option_prefix_for_keys_that_need_them
    assert_equal ['--long', '-s'], options_str('long' => true, 's' => true)
  end

  def test_options_str_reformats_symbol_keys_with_dashes
    assert_equal ['--long-opt'], options_str(:long_opt => true)
  end

  def test_options_str_sorts_options_such_that_short_options_win
    assert_equal %w{
      --a-long --b-long --c-long -a -b -c
    }, options_str(
      'a' => true, 'b' => true, 'c' => true,
      'a-long' => true, 'b-long' => true, 'c-long' => true
    )
  end

  #
  # option_quote test
  #

  def test_option_quote_does_not_quote_options
    assert_equal %{--option}, option_quote("--option")
    assert_equal %{-o}, option_quote("-o")
  end

  #
  # quote test
  #

  def test_quote_encloses_arg_in_quotation_marks
    assert_equal %{"abc"}, quote("abc")
  end

  def test_quote_does_not_double_quote
    assert_equal %{"abc"}, quote('"abc"')
    assert_equal %{'abc'}, quote("'abc'")
  end

  #
  # quoted? test
  #

  def test_quoted_check_returns_true_if_arg_is_quoted_by_quotation_marks_or_apostrophes
    assert_equal false, quoted?("abc")
    assert_equal true,  quoted?("'abc'")
    assert_equal true,  quoted?('"abc"')
  end
end