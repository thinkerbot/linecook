require File.expand_path('../../test_helper', __FILE__)
require 'linecook/recipe'

class RecipeTest < Test::Unit::TestCase
  include ShellTest
  include FileMethodsShim

  Recipe   = Linecook::Recipe
  Package  = Linecook::Package
  Cookbook = Linecook::Cookbook

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
    assert_equal outdent(expected), recipe.to_s
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
    recipe = Recipe.new do
      _extend_ Helper
      echo 'a', 'b c'
      echo 'X Y'.downcase, :z
    end

    expected = %{
echo 'a b c'
echo 'x y z'
}
    assert_equal expected, "\n" + recipe.to_s
  end

  #
  # _ test
  #

  def test___returns_child_recipe_with_new_target
    recipe.write "abc"
    child = recipe._
    child.write "xyz"

    assert_equal recipe._package_, child._package_
    assert_equal recipe._cookbook_, child._cookbook_

    assert_equal "abc", recipe.to_s
    assert_equal "xyz", child.to_s
  end

  def test___inherits_attributes
    child = recipe._
    assert_equal recipe.attributes, child.attributes
  end

  module ChildHelpers
    def a
      :a
    end
  end

  def test___inherits_helpers
    recipe.helpers ChildHelpers
    child = recipe._
    assert_equal :a, child.a
  end

  def test___writes_str_to_child_if_given
    child = recipe._("abc")
    assert_equal "abc", child.to_s
  end

  def test___evaluates_block_in_contenxt_of_child_if_given
    child = recipe._ { write "abc" }
    assert_equal "abc", child.to_s
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

  def test_capture_reassigns_target_for_block
    setup_recipe do
      write 'a'
      capture do
        write 'b'
      end
      write 'c'
    end

    assert_equal "ac", recipe.to_s
  end

  def test_capture_returns_capture_target
    target = recipe.capture { recipe.write 'abc' }
    assert_equal "abc", target
  end

  #
  # write test
  #

  def test_write_writes_to_target
    recipe.write 'content'
    assert_equal 'content', recipe.to_s
  end

  #
  # writeln test
  #

  def test_writeln_writes_to_target
    recipe.writeln 'content'
    assert_equal "content\n", recipe.to_s
  end

  #
  # chain test
  #

  def test_chain_sets_chain_check_to_return_true
    assert_equal false, recipe.chain?
    recipe.chain
    assert_equal true, recipe.chain?
  end

  def test_chain_returns_self
    assert_equal recipe, recipe.chain
  end

  #
  # unchain test
  #

  def test_unchain_sets_chain_check_to_return_true
    recipe.chain
    assert_equal true, recipe.chain?
    recipe.unchain
    assert_equal false, recipe.chain?
  end

  def test_unchain_returns_self
    assert_equal recipe, recipe.unchain
  end

  #
  # chain_proxy test
  #

  def test_chain_proxy_unchains
    recipe.chain
    recipe.chain_proxy
    assert_equal false, recipe.chain?
  end

  def test_chain_proxy_returns__proxy_
    assert_equal recipe._proxy_, recipe.chain_proxy
  end

  #
  # to_s test
  #

  def test_to_s_returns_target
    recipe.write "content"
    assert_equal "content", recipe.to_s
  end

  def test_to_s_allows_further_modification
    recipe.write 'abc'

    assert_equal 'abc', recipe.to_s
    assert_equal 'abc', recipe.to_s

    recipe.write 'xyz'

    assert_equal 'abcxyz', recipe.to_s
  end
end