class PosixTest < Test::Unit::TestCase
  include Linecook::Test

  #
  # quote test
  #

  # Section 2.2 Quoting
  SPECIAL_CHARS = %w{ | & ; < > ( ) $ ` \ " ' } + [" ", "\t", "\n"] + %w{ * ? [ # ˜ = % }

  # Quotes are special special chars
  NON_QUOTE_SPECIAL_CHARS = SPECIAL_CHARS - %w{ " ' }

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
  # literal test
  #

  def test_literal_does_not_quote_strings_without_special_chars
    assert_equal %{cat}, literal("cat")
  end

  def test_literal_single_quotes_strings_with_special_chars
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{'#{char}'}, literal(char)
    end
    assert_equal %{'"'}, literal(%{"})
  end

  def test_literal_escapes_apostrophes
    assert_equal %q{\'\'\'}, literal(%{'''})
  end

  def test_literal_singe_quotes_and_escapes_strings_with_apostrophes
    assert_equal %q{'ab'\'},   literal(%q{ab'})
    assert_equal %q{'a'\''b'}, literal(%q{a'b})
    assert_equal %q{\''ab'},   literal(%q{'ab})
  end

  def test_literal_single_quotes_quoted_strings
    NON_QUOTE_SPECIAL_CHARS.each do |char|
      assert_equal %{'"#{char}"'}, literal(%{"#{char}"})
      assert_equal %{\\''#{char}'\\'}, literal(%{'#{char}'})
    end

    assert_equal %q{'"'\''"'}, literal(%{"'"})
    assert_equal %q{\''"'\'},  literal(%{'"'})

    assert_equal %q{'"cat"'},   literal(%q{"cat"})
    assert_equal %q{\''cat'\'}, literal(%q{'cat'})
  end

  #
  # reserved_word? test
  #

  # Section 2.4 Reserved Words
  RESERVED_WORDS = %w[ ! { } case do done elif else esac fi for if in then until while ] + %w( [[ ]] function select )

  def test_reserved_word_check_returns_true_for_reserved_words
    RESERVED_WORDS.each do |word|
      assert reserved_word?(word), word
    end
  end

  def test_concatenation_of_name_and_colon_is_reserved
    assert reserved_word?("name:")
  end

  #
  # name? test
  # Section 3.230 Name

  def test_name_check_returns_true_for_strings_with_word_chars_only
    assert_equal true, name?("A_b_1")
    assert_equal false, name?("A b")
  end

  def test_name_check_returns_false_for_strings_beginning_with_a_number
    assert_equal false, name?("1ab")
  end

  #
  # var test (Variable)
  #

  def test_var_raises_error_for_invalid_name
    err = assert_equal(InvalidNameError) { var "1ab" }
    assert_equal %{invalid name: "1ab"}, err.message
  end

  def test_var_arithmetic_returns_new_var_with_arithmetic_expansion
    a = var 'a'
    b = var 'b'
    c = var 'c'
    assert_equal "$(( $a + $b ))", (a + b).to_s
    assert_equal "$(( $(( $a + $b )) + $c ))", (a + b + c).to_s
  end

  #
  # params test
  #

  # Section 2.5.2 
  SPECIAL_PARAMETERS = %w{ @ * # ? - $ ! 0 }

  def test_argv_returns_var_for_at_sign
    assert_equal "$@", argv.to_s
  end

  def test_argstr_returns_var_for_asterix
    assert_equal "$*", argstr.to_s
  end

  def test_n_args_returns_var_for_asterix
    assert_equal "$#", n_args.to_s
  end

  def test_status_returns_var_for_question_mark
    assert_equal "$?", status.to_s
  end

  def test_option_flags_returns_var_for_hypen
    assert_equal "$-", option_flags.to_s
  end

  def test_shell_pid_returns_var_for_dollar_sign
    assert_equal "$$", shell_pid.to_s
  end

  def test_job_pid_returns_var_for_dollar_sign
    assert_equal "$!", job_pid.to_s
  end

  def test_program_name_returns_var_for_zero
    assert_equal "$0", program_name.to_s
  end

  #
  # subcmd test (Variable)
  #

  #
  # redirect test (Redirect)
  #

  #
  # command test (Command)
  #

  def test_commands_accept_variables_as_inputs
    a = var 'a'
    assert_equal %{echo "$a"}, command("echo", a)
  end

  def test_commands_chain_into_pipelines
    a = command "echo", "a"
    b = command "tr", "a", "b"
    assert_equal %{echo a | tr a b}, a.b.to_s
  end

  def test_commands_chain_redirects
    a = command "echo", "a"
    b = redirect 1, 'file', '>>'
    assert_equal %{echo a >> file}, a.b.to_s
  end

  #
  # compound (Compound)
  #

  def test_compound_represents_a_list_of_commands
    a = command "echo", "a"
    b = command "echo", "b"
    assert_equal "echo a\necho b", compound(a, b).to_s
  end

  def test_compound_commands_can_be_replaced
    a = command "echo", "a"
    b = command "echo", "b"
    c = compound(a, b)
    d = command "tr", "a", "b"

    c.replace a, a.d
    assert_equal "echo a | tr a b\necho b", c.to_s
  end

  def test_chain_replaces_self_in_compound
    list = compound do
      a = command "echo", "a"
      b = command "echo", "b"
      c = command "tr", "a", "b"

      a.c
    end

    assert_equal "echo a | tr a b\necho b", list.to_s
  end

  #
  # function test (Command)
  #

end