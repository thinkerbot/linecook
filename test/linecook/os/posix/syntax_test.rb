require File.expand_path('../../../../test_helper', __FILE__)
require 'linecook/os/posix/syntax'

class SyntaxTest < Test::Unit::TestCase
  include Linecook::Os::Posix::Syntax

  NON_QUOTE_SPECIAL_CHARS = SPECIAL_CHARS - %w{ " ' }

  #
  # needs_quote? test
  #

  def assert_needs_quote(str)
    assert needs_quote?(str), str
  end

  def test_needs_quote_check_returns_true_if_str_includes_special_chars
    assert_needs_quote "|"
    assert_needs_quote "&"
    assert_needs_quote ";"
    assert_needs_quote "<"
    assert_needs_quote ">"
    assert_needs_quote "("
    assert_needs_quote ")"
    assert_needs_quote "$"
    assert_needs_quote "`"
    assert_needs_quote "\\"
    assert_needs_quote "\""
    assert_needs_quote "'"
    assert_needs_quote " "
    assert_needs_quote "\t"
    assert_needs_quote "\n"
    assert_needs_quote "*"
    assert_needs_quote "?"
    assert_needs_quote "["
    assert_needs_quote "#"
    assert_needs_quote "~"
    assert_needs_quote "="
    assert_needs_quote "%"
    assert_equal false, needs_quote?('abc')
  end

  #
  # quote test
  #

  def test_quote_does_not_quote_strings_without_special_chars
    assert_equal %{cat}, quote("cat")
  end

  def test_quote_quotes_strings_with_special_chars
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{"#{char}"}, quote(char)
    end
    assert_equal %{"'"}, quote(%{'})
  end

  def test_quote_quotes_and_escapes_strings_with_quotes
    assert_equal %q{"ab\""}, quote(%q{ab"})
    assert_equal %q{"a\"b"}, quote(%q{a"b})
    assert_equal %q{"\"ab"}, quote(%q{"ab})
  end

  def test_quote_does_not_quote_already_quoted_strings
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{"#{char}"}, quote(%{"#{char}"})
      assert_equal %{'#{char}'}, quote(%{'#{char}'})
    end

    assert_equal %{"'"}, quote(%{"'"})
    assert_equal %{'"'}, quote(%{'"'})

    assert_equal %{"cat"}, quote(%{"cat"})
    assert_equal %{'cat'}, quote(%{'cat'})
  end

  def test_quote_does_not_check_grammer
    assert_equal %{"$(incomplete subshell"}, quote(%{$(incomplete subshell})
    assert_equal %{"`unmatched backquote"},  quote(%{`unmatched backquote})
  end

  #
  # single_quote test
  #

  def test_single_quote_does_not_quote_strings_without_special_chars
    assert_equal %{cat}, single_quote("cat")
  end

  def test_single_quote_single_quotes_strings_with_special_chars
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{'#{char}'}, single_quote(char)
    end
    assert_equal %{'"'}, single_quote(%{"})
  end

  def test_single_quote_escapes_apostrophes
    assert_equal %q{\'\'\'}, single_quote(%{'''})
  end

  def test_single_quote_singe_quotes_and_escapes_strings_with_apostrophes
    assert_equal %q{'ab'\'},   single_quote(%q{ab'})
    assert_equal %q{'a'\''b'}, single_quote(%q{a'b})
    assert_equal %q{\''ab'},   single_quote(%q{'ab})
  end

  def test_single_quote_single_quotes_quoted_strings
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{'"#{char}"'}, single_quote(%{"#{char}"})
      assert_equal %{\\''#{char}'\\'}, single_quote(%{'#{char}'})
    end

    assert_equal %q{'"'\''"'}, single_quote(%{"'"})
    assert_equal %q{\''"'\'},  single_quote(%{'"'})

    assert_equal %q{'"cat"'},   single_quote(%q{"cat"})
    assert_equal %q{\''cat'\'}, single_quote(%q{'cat'})
  end

  #
  # name? test
  #

  def assert_name(word)
    assert name?(word), word
  end

  def test_name_returns_true_if_the_str_consists_of_only_word_chars
    assert_name 'ABCabc_123'
    assert_name 'abc_123ABC'
    assert_name '_123ABCabc'
    assert_equal false, name?('&abc')
  end

  def test_name_returns_false_if_str_starts_with_a_number
    assert_equal false, name?('123ABCabc_')
  end

  def test_name_returns_false_for_empty_str
    assert_equal false, name?('')
  end

  #
  # reserved_word? test
  #

  def assert_reserved_word(word)
    assert reserved_word?(word), word
  end
  
  def test_reserved_word_check_returns_true_for_reserved_words
    assert_reserved_word '!'
    assert_reserved_word '{'
    assert_reserved_word '}'
    assert_reserved_word 'case'
    assert_reserved_word 'do'
    assert_reserved_word 'done'
    assert_reserved_word 'elif'
    assert_reserved_word 'else'
    assert_reserved_word 'esac'
    assert_reserved_word 'fi'
    assert_reserved_word 'for'
    assert_reserved_word 'if'
    assert_reserved_word 'in'
    assert_reserved_word 'then'
    assert_reserved_word 'until'
    assert_reserved_word 'while'
    assert_reserved_word '[['
    assert_reserved_word ']]'
    assert_reserved_word 'function'
    assert_reserved_word 'select'
    assert_equal false, reserved_word?('abc')
  end

  def test_concatenation_of_name_and_colon_is_reserved
    assert_reserved_word "name:"
  end
end