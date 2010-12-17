require File.expand_path('../test_helper', __FILE__)

class LineCookTest < Test::Unit::TestCase
  include LineCook::TestHelper
  
  LINE_COOK = File.expand_path('../../bin/line_cook', __FILE__)
  LINE_COOK_LIB = File.expand_path('../../lib', __FILE__)
  
  def test_line_cook_generates_a_cookbook_directory
    example_dir = path('example')
    assert_equal false, File.exists?(example_dir)
    
    output = `ruby #{LINE_COOK} example`
    assert_equal 0, $?.exitstatus, output
    
    Dir.chdir(example_dir) do
      output = `rake -I#{LINE_COOK_LIB} -Ihelpers --silent scripts`
      assert_equal 0, $?.exitstatus, output
      
      output = `sh scripts/example/example`
      assert_equal 0, $?.exitstatus, output
      assert_equal "a b c\n", output
    end
  end
  
  def test_line_cook_does_not_overwrite_existing_directory
    example_dir = path('example')
    FileUtils.mkdir_p(example_dir)
    
    output = `ruby #{LINE_COOK} example`
    assert_equal 1, $?.exitstatus
    
    assert_equal [], Dir.glob("#{example_dir}/*")
  end
  
  def test_line_cook_regenerates_cookbook_on_force
    example_readme = path('example/README')
    
    output = `ruby #{LINE_COOK} example`
    assert_equal 0, $?.exitstatus, output
    
    assert_equal true, File.exists?(example_readme)
    FileUtils.rm(example_readme)
    
    output = `ruby #{LINE_COOK} example --force`
    assert_equal 0, $?.exitstatus, output
    
    assert_equal true, File.exists?(example_readme)
  end
  
  def test_line_cook_does_not_allow_force_for_parent_dirs_or_current_dir
    example_dir = path('parent/current')
    FileUtils.mkdir_p(example_dir)
    
    Dir.chdir(example_dir)
    output = `ruby #{LINE_COOK} . --force`
    assert_equal 1, $?.exitstatus
    
    output = `ruby #{LINE_COOK} .. --force`
    assert_equal 1, $?.exitstatus
    
    assert_equal [example_dir], Dir.glob(path('parent/*'))
    assert_equal [], Dir.glob(path('parent/current/*'))
  end
end