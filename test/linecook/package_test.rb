require File.expand_path('../../test_helper', __FILE__)
require 'linecook/package'
require 'tempfile'
require 'ostruct'

class PackageTest < Test::Unit::TestCase
  include ShellTest
  include FileMethodsShim

  Package = Linecook::Package

  attr_accessor :package

  def setup
    super
    @package = Package.new
  end

  #
  # register test
  #

  def test_register_registers_source_to_path
    source_path = path('source/path')
    package.register('target/path', source_path)
    assert_equal source_path, package.registry['target/path']
  end

  def test_register_expands_source_path
    assert_equal File.expand_path('source/path'), package.register('target/path', 'source/path')
  end

  def test_register_raises_error_if_path_is_already_registered
    package.register('target/path', 'source/a')
    err = assert_raises(RuntimeError) { package.register('target/path', 'source/b') }
    assert_equal %{already registered: "target/path"}, err.message
  end

  def test_register_accepts_export_options
    package.register('target/path', 'source/path', :move => true)
    assert_equal true, package.export_options['target/path'][:move]
  end

  #
  # unregister test
  #

  def test_unregister_removes_path_from_registry
    package.register('target/path', 'source/a')
    package.unregister('target/path')
    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # add test
  #

  def test_add_adds_and_returns_a_tempfile_at_the_specified_path
    tempfile = package.add('target/path')
    assert_equal Tempfile, tempfile.class
    assert_equal false, tempfile.closed?
    assert_equal tempfile.path, package.source_path('target/path')
  end

  def test_added_tempfiles_are_marked_for_move_by_default
    package.add('target/path')
    assert_equal true, package.export_options['target/path'][:move]
  end

  def test_add_accepts_export_options
    package.add('target/path', :mode => 0640, :move => false)
    assert_equal 0640, package.export_options['target/path'][:mode]
    assert_equal false, package.export_options['target/path'][:move]
  end

  #
  # add_dir test
  #

  def test_add_dir_registers_a_directory_in_registry_at_the_specified_path
    package.add_dir('target/dir')
    assert_equal :dir, package.source_path('target/dir')
  end

  def test_add_dir_accepts_export_options
    package.add_dir('target/dir', :mode => 0640)
    assert_equal 0640, package.export_options['target/dir'][:mode]
  end

  #
  # rm test
  #

  def test_rm_removes_path_from_registry
    package.register('target/path', 'source/a')
    package.rm('target/path')
    assert_equal false, package.registry.has_key?('target/path')
  end

  #
  # source_path test
  #

  def test_source_path_returns_the_source_path_registered_to_the_path
    source = package.add('target/path')
    assert_equal source.path, package.source_path('target/path') 
  end

  def test_source_path_returns_nil_if_nothing_is_registered_to_path
    assert_equal nil, package.source_path('target/path')
  end

  #
  # paths test
  #

  def test_paths_returns_all_package_paths_that_register_the_source
    source_path = path('source/path')
    package.register('target/a', source_path)
    package.register('target/b', source_path)
    assert_equal ['target/a', 'target/b'], package.paths(source_path)
  end

  #
  # content test
  #

  def test_content_returns_the_contents_of_the_target
    source_path = prepare('source', 'content')
    package.register 'target/path', source_path
    assert_equal 'content', package.content('target/path')
  end

  def test_content_returns_the_specified_length_and_offset
    source_path = prepare('source', 'content')
    package.register 'target/path', source_path
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_the_specified_length_and_offset_for_source
    package.add('target/path') {|io| io << 'content' }
    assert_equal 'nte', package.content('target/path', 3, 2)
  end

  def test_content_returns_nil_for_unregistered_target
    assert_equal nil, package.content('not/added')
  end

  #
  # next_path test
  #

  def test_next_path_increments_path_name_if_already_registered
    assert_equal 'target/path',   package.next_path('target/path')

    package.register('target/path', 'source')
    assert_equal 'target/path.1', package.next_path('target/path')

    package.register('target/path.1', 'source')
    assert_equal 'target/path.2', package.next_path('target/path')
  end

  #
  # on_export test
  #

  def test_on_export_sets_export_options_for_path
    package.on_export('target/path', :move => true)
    assert_equal true, package.export_options['target/path'][:move]
  end

  def test_on_export_merges_default_export_options_unless_specified
    package.register('target/path', 'source/path')
    package.default_export_options[:mode] = 0640
    package.on_export 'target/path', :move => true

    assert_equal 0640, package.export_options['target/path'][:mode]
    assert_equal true, package.export_options['target/path'][:move]
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

  def test_export_moves_sources_for_targets_marked_for_move
    source_path = prepare('source', 'content')
    package.register('target/path', source_path, :move => true)
    package.export path('export/dir')

    assert_equal false, File.exists?(source_path)
    assert_equal 'content', File.read(path('export/dir/target/path'))
  end

  def test_export_makes_empty_file_for_targets_with_file_source_path
    package.register('target/path', :file)
    package.export path('export/dir')

    assert_equal "", content('export/dir/target/path')
  end

  def test_export_makes_directories_for_targets_with_dir_source_path
    package.register('target/path', :dir)
    package.export path('export/dir')

    assert_equal true, File.directory?(path('export/dir/target/path'))
  end

  def test_export_recursively_copies_directories
    prepare('source/dir/a', 'a')
    prepare('source/dir/b/c', 'c')

    package.register('target/path', path('source/dir'))
    package.export path('export/dir')

    assert_equal 'a', content('export/dir/target/path/a')
    assert_equal 'c', content('export/dir/target/path/b/c')
    assert_equal 'a', content('source/dir/a')
    assert_equal 'c', content('source/dir/b/c')
  end

  def test_export_moves_directories_marked_for_move
    prepare('source/dir/a', 'a')
    prepare('source/dir/b/c', 'c')

    package.register('target/path', path('source/dir'), :move => true)
    package.export path('export/dir')

    assert_equal 'a', content('export/dir/target/path/a')
    assert_equal 'c', content('export/dir/target/path/b/c')
    assert_equal false, File.exists?(path('source/dir'))
  end

  def test_export_exports_directories_and_nested_files_without_issue
    prepare('source/dir/a', 'a')
    prepare('source/dir/b/c', 'c')

    package.register('dir', path('source/dir'))
    package.add('dir/file.txt') {|io| io << 'content' }
    package.export path('export')

    assert_equal 'content', File.read(path('export/dir/file.txt'))
    assert_equal 'a', content('export/dir/a')
    assert_equal 'c', content('export/dir/b/c')
  end

  def test_export_sets_the_mode_for_the_target_as_specified_in_export_options
    source_path = prepare('source', 'content')
    package.register('target/path', source_path, :mode => 0640)
    package.export path('export/dir')

    assert_equal '100640', mode('export/dir/target/path')
  end

  def test_export_rewrites_and_returns_registry_with_new_source_paths
    source_path = prepare('source', 'content')
    package.register('target/path', source_path)
    registry = package.export path('export/dir')

    assert_equal path('export/dir/target/path'), registry['target/path']
  end

  def test_export_can_be_used_to_update_an_export
    source_path = prepare('source', 'content')
    package.register('target/path', source_path)

    package.on_export('target/path', :mode => 0640)
    package.export path('export/dir')

    package.on_export('target/path', :mode => 0600)
    package.export path('export/dir')

    assert_equal '100600', mode('export/dir/target/path')
  end

  def test_export_allows_export_into_existing_directory
    prepare 'dir/a', 'a'
    package.add('b') {|io| io << 'b' }

    package.export path('dir')
    assert_equal 'a', content('dir/a')
    assert_equal 'b', content('dir/b')
  end

  def test_export_raises_error_for_existing_file
    prepare 'dir/file', 'previous'
    package.add('file') {|io| io << 'current' }

    err = assert_raises(RuntimeError) { package.export path('dir') }
    assert_equal "already exists: #{path('dir/file').inspect}", err.message
    assert_equal 'previous', content('dir/file')
  end

  def test_export_continues_export_if_block_returns_true_for_existing_file
    prepare 'dir/file', 'previous'
    package.add('file') {|io| io << 'current' }

    package.export path('dir') do |src, dest|
      true
    end

    assert_equal 'current', content('dir/file')
  end

  def test_export_skips_if_block_returns_false_for_existing_file
    prepare 'dir/file', 'previous'
    package.add('file') {|io| io << 'current' }

    package.export path('dir') do |src, dest|
      false
    end

    assert_equal 'previous', content('dir/file')
  end
end