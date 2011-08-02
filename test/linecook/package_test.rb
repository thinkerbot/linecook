require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'
require 'tempfile'
require 'ostruct'

class PackageTest < Test::Unit::TestCase
  include ShellTest

  Package = Linecook::Package

  attr_accessor :package

  def setup
    super
    @package = Package.new
  end

  #
  # resolve_source_path test
  #

  def test_resolve_source_path_resolves_sources_to_path_using_path_method
    source = OpenStruct.new :path => '/source/path'
    assert_equal '/source/path', package.resolve_source_path(source)
  end

  def test_resolve_source_path_uses_source_as_path_if_it_does_not_have_a_path_method
    assert_equal '/source/path', package.resolve_source_path('/source/path')
  end

  def test_resolve_source_path_expands_path
    assert_equal File.expand_path('source/path'), package.resolve_source_path('source/path')
  end

  #
  # add test
  #

  def test_add_registers_source_path_to_target_path
    package.add('target/path', 'source/path')
    assert_equal File.expand_path('source/path'), package.registry['target/path']
  end

  def test_add_resolves_sources_to_path_before_register
    source = Tempfile.new('source')
    package.add('target/path', source)
    assert_equal source.path, package.registry['target/path']
  end

  def test_add_raises_error_for_target_path_added_to_a_different_source
    package.add('target/path', 'source/a')

    err = assert_raises(RuntimeError) { package.add('target/path', 'source/b') }
    assert_equal %{already registered: "target/path" ("#{File.expand_path('source/a')}")}, err.message
  end

  def test_add_does_not_raise_error_for_double_add_of_same_source_and_target_path
    package.add('target/path', 'source/a')
    assert_nothing_raised { package.add('target/path', 'source/a') }
  end

  #
  # rm test
  #

  def test_rm_removes_target_path_from_registry
    package.add('target/path', 'source/a')
    package.rm('target/path')
    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # unregister test
  #

  def test_unregister_removes_source_path_from_registry
    package.add('target/a', 'source/one')
    package.add('target/b', 'source/one')
    package.add('target/c', 'source/two')
    package.unregister('source/one')

    assert_equal({'target/c' => File.expand_path('source/two')}, package.registry)
  end

  def test_unregister_resolves_source_to_source_path
    source = Tempfile.new('source')
    package.add('target/path', source.path)
    package.unregister(source)

    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # content test
  #

  def test_content_returns_the_contents_of_the_target
    source_path = prepare('source', 'content')
    package.add 'target/path', source_path
    assert_equal 'content', package.content('target/path')
  end

  def test_content_returns_the_specified_length_and_offset
    source_path = prepare('source', 'content')
    package.add 'target/path', source_path
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_nil_for_unadded_target
    assert_equal nil, package.content('not/added')
  end

  #
  # on_export test
  #

  def test_on_export_sets_export_options_for_source
    source = Tempfile.new('source')
    package.on_export(source, :move => true)

    assert_equal({:move => true}, package.export_opts[source.path])
  end

  #
  # export test
  #

  def test_export_copies_source_files_to_dir_as_specified_in_registry
    original_source = prepare('example') {|io| io << 'content'}

    package.registry['target/path'] = original_source
    package.export path('export/dir')

    assert_equal 'content', File.read(original_source)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end

  def test_export_moves_sources_marked_for_move
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    package.on_export(source_path, :move => true)

    package.export path('export/dir')

    assert_equal false, File.exists?(source_path)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end

  def test_export_chmods_the_exported_file_as_specified_in_export_opts
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    package.on_export(source_path, :mode => 0640)

    package.export path('export/dir')

    mode = File.stat(path('export/dir/target/path')).mode
    assert_equal '100640', sprintf("%o", mode)
  end

  def test_export_rewrites_and_returns_registry_with_new_source_paths
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    registry = package.export path('export/dir')
    assert_equal path('export/dir/target/path'), registry['target/path']
  end

  def test_export_rewrites_export_opts_to_new_source_paths
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)
    package.on_export(source_path, :mode => 0640)

    package.export path('export/dir')

    assert_equal({
      path('export/dir/target/path') => {:mode => 0640}
    }, package.export_opts)
  end

  def test_export_can_be_used_to_update_an_export
    source_path = prepare('source', 'content')
    package.add('target/path', source_path)

    package.on_export(source_path, :mode => 0640)
    package.export path('export/dir')
    package.on_export(package.registry['target/path'], :mode => 0600)
    package.export path('export/dir')

    mode = File.stat(path('export/dir/target/path')).mode
    assert_equal '100600', sprintf("%o", mode)
  end
end