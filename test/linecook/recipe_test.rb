require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'

class RecipeTest < Test::Unit::TestCase
  include ShellTest
  include FileMethodsShim

  Recipe   = Linecook::Recipe
  Package  = Linecook::Recipe
  Cookbook = Linecook::Recipe
  Document = Linecook::Document

  # Note these methods are similar to those in Linecook::Test but I prefer to
  # repeat them to keep Recipe tests separate from the Test module tests,
  # which depend on Recipe, and thereby prevent a circular test setup.

  def recipe
    @recipe ||= Recipe.new
  end

  def package
    recipe._package_
  end

  def cookbook
    recipe._cookbook_
  end

  def setup_recipe(&block)
    @recipe = Recipe.new
    @recipe.instance_eval(&block) if block
    @recipe
  end

  def assert_recipe(expected, &block)
    setup_recipe(&block)
    assert_equal outdent(expected), recipe._result_
  end

  #
  # documentation test
  #

  module Helper
    # This is an ERB template compiled to write to a Recipe.
    #
    #   compiler = ERB::Compiler.new('<>')
    #   compiler.put_cmd = "write"
    #   compiler.insert_cmd = "write"
    #   compiler.compile("echo '<%= args.join(' ') %>'\n")
    #
    def echo(*args)
      write "echo '"; write(( args.join(' ') ).to_s); write "'\n"
    end
  end

  def test_recipe_documentation
    recipe  = Recipe.new do
      _extend_ Helper
      echo 'a', 'b c'
      echo 'X Y'.downcase, :z
    end

    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + recipe._result_
  end

  #
  # _ test
  #

  def test___returns_child_recipe_with_new_document
    recipe.write "abc"
    child = recipe._
    child.write "xyz"

    assert_equal recipe._package_, child._package_
    assert_equal recipe._cookbook_, child._cookbook_

    assert_equal "abc", recipe._result_
    assert_equal "xyz", child._result_
  end

  def test___child_inherits__locals__
    child = recipe._
    assert_equal recipe._locals_, child._locals_
  end

  def test___child_inherits_attributes
    child = recipe._
    assert_equal recipe.attributes, child.attributes
  end

  def test___writes_str_to_child_if_given
    child = recipe._("abc")
    assert_equal "abc", child._result_
  end

  def test___evaluates_block_in_contenxt_of_child_if_given
    child = recipe._ { write "abc" }
    assert_equal "abc", child._result_
  end

  #
  # _capture_ test
  #

  def test__capture__reassigns_doc_for_block
    setup_recipe do
      write 'a'
      _capture_ do
        write 'b'
      end
      write 'c'
    end

    assert_equal "ac", recipe._result_
  end

  #
  # _result_ test
  #

  def test__result__returns_formatted_doc_content
    recipe._doc_.set :indent => '..'
    recipe._doc_.writeln 'content'
    assert_equal "..content\n", recipe._result_
  end

  def test__result__allows_further_modification
    recipe.write 'abc'

    assert_equal 'abc', recipe._result_
    assert_equal 'abc', recipe._result_

    recipe.write 'xyz'

    assert_equal 'abcxyz', recipe._result_
  end

  #
  # attributes test
  #

  def test_attributes_evals_the_attributes_file_in_the_context_of_attributes
    path = prepare('example.rb') {|io| io << "attrs[:key] = 'value'"}
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes(path)
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_evals_a_block_for_attrs
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes do
      attrs[:key] = 'value'
    end

    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_loads_yml_files_as_yaml
    path = prepare('example.yml') {|io| io << ":key: value" }
    assert_equal nil, recipe.attrs[:key]

    recipe.attributes(path)
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_looks_for_files_along_attributes_path
    prepare('attributes/example.yml') {|io| io << ":key: value" }
    cookbook.add(method_dir)

    recipe.attributes('example.yml')
    assert_equal 'value', recipe.attrs[:key]
  end

  def test_attributes_checks_rb_and_yaml_formats
    prepare 'attributes/a.rb', 'attrs[:one] = "A"'
    prepare 'attributes/b.yml', ':two: B'
    cookbook.add(method_dir)

    recipe.attributes('a')
    recipe.attributes('b')
    assert_equal 'A', recipe.attrs[:one]
    assert_equal 'B', recipe.attrs[:two]
  end

  #
  # attrs test
  #

  def test_attrs_merges_attrs_and_env_where_env_wins
    package.env[:a] = 'A'

    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = 'B'
    end

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
  end

  def test_attrs_are_additive_and_still_ensure_env_wins
    package.env[:a] = 'A'

    recipe.attributes do
      attrs[:a]     = '-'
      attrs[:b]     = '-'
      attrs[:c]     = 'C'
    end

    recipe.attributes do
      attrs[:b]     = 'B'
    end

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal 'C', recipe.attrs[:c]
  end

  def test_attrs_performs_deep_merge
    recipe.attributes do
      attrs[:a] = 'A'
      attrs[:b] = '-'
      attrs[:one][:a] = 'a'
      attrs[:one][:b] = '-'
    end

    package.env[:b]   = 'B'
    package.env[:one] = {:b => 'b'}

    assert_equal 'A', recipe.attrs[:a]
    assert_equal 'B', recipe.attrs[:b]
    assert_equal({:a => 'a', :b => 'b'}, recipe.attrs[:one])
  end

  def test_attrs_does_not_auto_nest
    recipe.attributes { attrs[:b] }

    assert_equal nil, recipe.attrs[:a]
    assert_equal nil, recipe.attrs[:b][:c]
  end

  #
  # helper test
  #

  def test_helper_requires_helper_and_extends_with_module
    prepare 'lib/helper_module.rb', %{
      module HelperModule
        def helper_method
          :pass
        end
      end
    }

    lib_path = path 'lib'
    begin
      $:.unshift lib_path
      recipe.helpers 'helper_module'
    ensure
      $:.delete lib_path
    end

    assert_equal :pass, recipe.helper_method
  end

  #
  # capture test
  #

  def test_capture_captures_block_and_returns_output
    recipe.write 'a'
    str = recipe.capture { recipe.write 'b' }
    recipe.write str.upcase
    recipe.write 'c'

    assert_equal "aBc", recipe._result_
  end

  #
  # write test
  #

  def test_write_writes_to_target
    recipe.write 'content'
    assert_equal 'content', recipe._result_
  end

  #
  # writeln test
  #

  def test_writeln_writes_to_target
    recipe.writeln 'content'
    assert_equal "content\n", recipe._result_
  end

  #
  # indent test
  #

  def test_indent_increases_indent_by_one_level_during_block
    assert_recipe %q{
      a
        b
        b
      a
    } do
      writeln 'a'
      indent do
        writeln 'b'
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_indents_may_be_nested
    assert_recipe %q{
      a
        b
          c
          c
        b
      a
    } do
      writeln 'a'
      indent do
        writeln 'b'
        indent do
          writeln 'c'
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_indent_allows_indent_by_more_than_one_level
    assert_recipe %q{
      a
          b
          b
      a
    } do
      writeln 'a'
      indent(2) do
        writeln 'b'
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_indent_allows_specification_of_a_specific_indent_str
    assert_recipe %q{
      a
      ..b
      .c
      .c
      ..b
      a
    } do
      writeln 'a'
      indent('..') do
        writeln 'b'
        indent('.') do
          writeln 'c'
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end
  end

  #
  # outdent test
  #

  def test_outdent_sets_indent_level_to_zero_for_duration_of_block
    assert_recipe %q{
      a
      .b
      c
      .x
      ..y
      z
      z
      ..y
      .x
      c
      .b
      a
    } do
      writeln 'a'
      indent('.') do
        writeln 'b'
        outdent do
          writeln 'c'
          indent do
            writeln 'x'
            indent do
              writeln 'y'
              outdent do
                writeln 'z'
                writeln 'z'
              end
              writeln 'y'
            end
            writeln 'x'
          end
          writeln 'c'
        end
        writeln 'b'
      end
      writeln 'a'
    end
  end

  def test_outdent_changes_indent_by_n_if_specified
    assert_recipe %{
      a
      ..b
      .c
      ..b
      a
    } do
      _doc_.set(:indent_str => '.')
      writeln "a"
      indent(2) do
        writeln "b"
        outdent(-1) do
          writeln "c"
        end
        writeln "b"
      end
      writeln "a"
    end
  end
end