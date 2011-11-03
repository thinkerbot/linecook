require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class LinecookTest < Test::Unit::TestCase
  include Linecook::Test
  include GemTestHelpers

  def setup
    super
    FileUtils.mkdir_p(method_dir)
    Dir.chdir(method_dir)
  end

  def test_linecook_prints_version_and_website
    assert_script %{
      $ #{LINECOOK_EXE} -v
      linecook version #{Linecook::VERSION} -- #{Linecook::WEBSITE}
    }
  end

  def test_linecook_prints_help
    assert_script_match %{
      $ #{LINECOOK_EXE} -h
      usage: linecook [options] COMMAND [ARGS]
      :....:
    }
  end

  def test_linecook_prints_help_when_no_args_are_given
    assert_script_match %{
      $ #{LINECOOK_EXE}
      usage: linecook [options] COMMAND [ARGS]
      :....:
    }
  end

  def test_linecook_prints_command_help
    assert_script_match %{
      % #{LINECOOK_EXE} compile -h
      usage: linecook compile :...:
      :....:
    }, :ps1 => '%'
  end

  #
  # lincook scripts test
  #

  def test_linecook_scp_and_linecook_run_work_with_the_same_defaults
    path = prepare "packages/#{host}/run", %{
      #!/bin/sh
      echo 'hello from #{host}'
    }
    FileUtils.chmod 0744, path

    Dir.chdir user_dir
    assert_script_match %{
      $ #{LINECOOK_PATH}_scp -F '#{ssh_config_file}' '#{path("packages/#{host}")}'
      $ #{LINECOOK_PATH}_run -F '#{ssh_config_file}' '#{path("packages/#{host}")}' <&-
      hello from #{host}
    }
  end

  #
  # compile test
  #

  def test_compile_documentation
    assert_script %{
      $ echo "write 'echo hello world'" > recipe.rb
      $ #{LINECOOK_EXE} compile recipe.rb
      $ sh recipe
      hello world
    }
  end

  def test_compile_compiles_the_recipe_in_a_file_named_like_the_relative_path_to_the_recipe
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile '#{recipe_path}'
    }

    assert_equal "echo hello world", content('path/to/recipe')
  end

  def test_compile_compiles_non_relative_recipes_by_basename
    tempfile = Tempfile.new('recipe.rb')
    tempfile << "write 'echo hello world'"
    tempfile.close
    name = File.basename(tempfile.path)

    assert_script %{
      $ #{LINECOOK_EXE} compile '#{tempfile.path}'
    }

    assert_equal "echo hello world", content(name)
  end

  def test_compile_compiles_multiple_recipes
    a = prepare 'a.rb', %{
      write 'echo hello a'
    }
    b = prepare 'b.rb', %{
      write 'echo hello b'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile '#{a}' '#{b}'
    }

    assert_equal "echo hello a", content('a')
    assert_equal "echo hello b", content('b')
  end

  def test_compile_stdin_to_stdout_on_dash
    recipe_path = prepare 'path/to/recipe.rb', %{
      writeln %{
        echo hello world
      }.strip
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile - < '#{recipe_path}'
      echo hello world
    }
  end

  def test_compile_allows_specification_of_input_dir
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -i '#{path('path/to')}' '#{recipe_path}'
    }

    assert_equal "echo hello world", content('recipe')
  end

  def test_compile_allows_specification_of_output_dir
    recipe_path = prepare 'recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -o dir '#{recipe_path}'
    }

    assert_equal "echo hello world", content('dir/recipe')
  end

  def test_compile_raises_error_if_script_exists
    recipe_path = prepare 'recipe.rb', %{
      write 'current'
    }
    prepare 'recipe', 'previous'

    assert_script %{
      $ #{LINECOOK_EXE} compile '#{recipe_path}' 2>&1 # [1]
      already exists: "#{path('recipe')}"
    }

    assert_equal 'previous', content('recipe')
  end

  def test_compile_overwrites_existing_script_on_force
    recipe_path = prepare 'recipe.rb', %{
      write 'current'
    }
    prepare 'recipe', 'previous'

    assert_script %{
      $ #{LINECOOK_EXE} compile -f '#{recipe_path}'
    }

    assert_equal 'current', content('recipe')
  end

  def test_compile_allows_specification_of_load_paths
    prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      Kernel.require 'echo'
      Echo.__send__(:extend_object, self)
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -Ilib '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  def test_compile_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      Echo.__send__(:extend_object, self)
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -r'#{echo_path}' '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  def test_compile_allows_specification_of_a_shared_package_file
    package_file = prepare 'recipe.yml', %{
      key: value
    }
    a = prepare 'a.rb', %{
      write attrs['key']
    }
    b = prepare 'b.rb', %{
      write attrs['key']
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -p '#{package_file}' '#{a}' '#{b}'
    }

    assert_equal 'value', content('a')
    assert_equal 'value', content('b')
  end

  def test_compile_compiles_helpers_if_specified
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }

    recipe_path = prepare 'recipe.rb', %{
      helpers 'example'
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -L helpers '#{recipe_path}'
    }

    assert_equal 'echo HELLO WORLD', content('recipe')
  end

  def prepare_default_module(spec)
    name, version = spec.name, spec.version
    prepare_gem_file spec, "templates/#{name}.erb", %{
      #{name} #{version} <%= msg %>
    }
    prepare_gem_file spec, "lib/#{name}.rb", %{
      module #{name.capitalize}
        def #{name}(str)
          write render('#{name}.erb', :msg => str)
        end
      end
    }
  end

  def check_default_module(name)
    %{
      begin
        helpers '#{name}'
        #{name} 'is available'
      rescue
        writeln '#{name} is not available'
      end
    }
  end

  def test_compile_allows_specification_of_gems_to_add_to_cookbook_path
    build_gem_fixture 'a', '1.0' do |spec|
      prepare_default_module(spec)
    end
    build_gem_fixture 'b', '1.0' do |spec|
      prepare_default_module(spec)
    end

    recipe_path = prepare 'recipe.rb', %{
      #{check_default_module('a')}
      #{check_default_module('b')}
    }

    with_gem_fixtures do
      assert_script %{
        $ #{LINECOOK_EXE} compile -G a '#{recipe_path}'
      }
    end

    assert_str_equal %{
      a 1.0 is available
      b is not available
    }, content('recipe')
  end

  def test_compile_allows_automatic_discovery_of_latest_cookbook_gems
    build_gem_fixture 'a', '1.0' do |spec|
      prepare_default_module(spec)
      prepare_gem_file spec, "cookbook.yml"
    end
    build_gem_fixture 'a', '2.0' do |spec|
      prepare_default_module(spec)
      prepare_gem_file spec, "cookbook.yml"
    end
    build_gem_fixture 'b', '1.0' do |spec|
      prepare_default_module(spec)
      prepare_gem_file spec, "cookbook.yml"
    end
    build_gem_fixture 'c', '1.0' do |spec|
      prepare_default_module(spec)
    end
    recipe_path = prepare 'recipe.rb', %{
      #{check_default_module('a')}
      #{check_default_module('b')}
      #{check_default_module('c')}
    }

    with_gem_fixtures do
      assert_script %{
        $ #{LINECOOK_EXE} compile -g '#{recipe_path}'
      }
    end

    assert_str_equal %{
      a 2.0 is available
      b 1.0 is available
      c is not available
    }, content('recipe')
  end

  def test_compile_with_common_flag_compiles_helpers_and_sets_cookbook_path
    prepare 'attributes/example.yml', %q{
      message: hello world
    }
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }
    prepare 'example.rb', %{
      attributes 'example'
      helpers 'example'
      upper_echo attrs['message']
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -c example.rb
    }

    assert_equal 'echo HELLO WORLD', content('example')
  end

  def test_compile_with_method_chaining
    prepare 'helpers/example/cat.erb', %{
      cat
    }
    prepare 'helpers/example/heredoc.erb', %{
      ()
      _rstrip_ if _chain_?
      --
       <<DOC
      <% yield %>
      DOC
    }

    recipe_path = prepare 'recipe.rb', %{
      helpers 'example'
      cat.heredoc do
        writeln 'a'
        writeln 'b'
        writeln 'c'
      end
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -L helpers '#{recipe_path}'
    }

    assert_str_equal %{
      cat <<DOC
      a
      b
      c
      DOC
    }, content('recipe')
  end

  def test_compile_with_capture_methods
    prepare 'helpers/example/echo.erb', %q{
      (str)
      --
      echo <%= str %>
    }

    recipe_path = prepare 'recipe.rb', %q{
      helpers 'example'
      write _echo('xyz').upcase
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -L helpers '#{recipe_path}'
    }

    assert_equal 'ECHO XYZ', content('recipe')
  end

  def test_compile_with_callbacks
    a = prepare 'a.rb', %q{
      callback 'cb' do
        write 'content'
      end
    }
    b = prepare 'b.rb', %q{
      write_callback 'cb'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile '#{a}' '#{b}'
    }

    assert_equal '', content('a')
    assert_equal 'content', content('b')
  end

  def test_compile_to_stdout_with_method_chains
    prepare 'helpers/example/cat.erb', %{
      cat
    }
    prepare 'helpers/example/heredoc.erb', %{
      ()
      _rstrip_ if _chain_?
      --
       <<DOC
      <% yield %>
      DOC
    }

    recipe_path = prepare 'recipe.rb', %{
      helpers 'example'
      cat.heredoc do
        writeln 'a'
        writeln 'b'
        writeln 'c'
      end
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile -L helpers - < '#{recipe_path}'
      cat <<DOC
      a
      b
      c
      DOC
    }
  end

  #
  # build test
  #

  def test_build_documentation
    assert_script %{
      $ echo "write 'echo ' + attrs['msg']" > recipe.rb
      $ echo "msg: hello world" > recipe.yml
      $ #{LINECOOK_EXE} build recipe.rb
      #{path('recipe')}
      $ recipe/run
      hello world
    }
    assert_script %{
      $ echo "write 'echo ' + attrs['msg']" > recipe.rb
      $ echo "msg: hello world" > input.yml
      $ #{LINECOOK_EXE} build input.yml,recipe.rb,output
      #{path('output')}
      $ output/run
      hello world
    }
  end

  def test_build_builds_the_recipe_in_a_dir_named_like_the_recipe_basename
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal "echo hello world", content('recipe/run')
  end

  def test_build_builds_multiple_recipes
    a = prepare 'a.rb', %{
      write 'echo hello a'
    }
    b = prepare 'b.rb', %{
      write 'echo hello b'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build '#{a}' '#{b}'
      #{path('a')}
      #{path('b')}
    }

    assert_equal "echo hello a", content('a/run')
    assert_equal "echo hello b", content('b/run')
  end

  def test_build_guesses_a_package_config_file_based_on_recipe_basename
    package_file = prepare 'recipe.yml', %{
      key: value
    }
    recipe_path  = prepare 'path/to/recipe.rb', %{
      write attrs['key']
    }

    assert_script %{
      $ #{LINECOOK_EXE} build '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_build_allows_specification_of_an_alternate_input_dir
    prepare 'packages/recipe.yml', %{
      key: value
    }
    recipe_path  = prepare 'recipe.rb', %{
      write attrs['key']
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -i '#{path('packages')}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'value', content('recipe/run')
  end

  def test_build_allows_specification_of_an_alternate_output_dir
    recipe_path = prepare 'recipe.rb', %{
      write 'echo hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -o '#{path('package')}' '#{recipe_path}'
      #{path('package/recipe')}
    }

    assert_equal "echo hello world", content('package/recipe/run')
  end

  def test_build_raises_error_if_package_dir_exists
    recipe_path = prepare 'recipe.rb', %{
      write 'current'
    }
    prepare 'recipe/run', 'previous'

    assert_script %{
      $ #{LINECOOK_EXE} build '#{recipe_path}' 2>&1 # [1]
      already exists: "#{path('recipe')}"
    }

    assert_equal 'previous', content('recipe/run')
  end

  def test_build_overwrites_package_dir_on_force
    recipe_path = prepare 'path/to/recipe.rb', %{
      write 'current'
    }
    prepare 'recipe/run', 'previous'

    assert_script %{
      $ #{LINECOOK_EXE} build -f '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'current', content('recipe/run')
  end

  def test_build_allows_specification_of_load_paths
    prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      Kernel.require 'echo'
      Echo.__send__(:extend_object, self)
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -Ilib '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_build_allows_specification_of_requires
    echo_path = prepare 'lib/echo.rb', %q{
      module Echo
        def upper_echo(str)
          write "echo #{str.upcase}"
        end
      end
    }

    recipe_path = prepare 'recipe.rb', %{
      Echo.__send__(:extend_object, self)
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -r'#{echo_path}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_build_compiles_helpers_if_specified
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }

    recipe_path = prepare 'recipe.rb', %{
      helpers 'example'
      upper_echo 'hello world'
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -L helpers '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'echo HELLO WORLD', content('recipe/run')
  end

  def test_build_can_specify_cookbook_directories
    prepare 'attributes/example.yml', 'obj: milk'
    prepare 'templates/example.erb', 'got <%= obj %>'
    recipe_path = prepare 'recipe.rb', %{
      attributes 'example'
      write render('example', attrs)
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -C '#{method_dir}' '#{recipe_path}'
      #{path('recipe')}
    }

    assert_equal 'got milk', content('recipe/run')
  end

  def test_build_with_common_flag_compiles_helpers_and_sets_cookbook_path
    prepare 'attributes/example.yml', %q{
      greeting: hello
    }
    prepare 'packages/example.yml', %q{
      thing: world
    }
    prepare 'helpers/example/upper_echo.rb', %q{
      (str)
      ---
      write "echo #{str.upcase}"
    }
    prepare 'recipes/example.rb', %q{
      attributes 'example'
      helpers 'example'
      upper_echo "#{attrs['greeting']} #{attrs['thing']}"
    }

    assert_script %{
      $ #{LINECOOK_EXE} build -c recipes/example.rb
      #{path('packages/example')}
    }

    assert_equal 'echo HELLO WORLD', content('packages/example/run')
  end

  #
  # compile_helper test
  #

  def test_compile_helper_compiles_source_files_to_helper_module
    source_file = prepare 'echo.erb', %{
      (str)
      --
      echo <%= str %>
    }

    recipe_path = prepare 'recipe.rb', %q{
      helpers 'example'
      echo 'abc'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example '#{source_file}'
      #{path('lib/example.rb')}
      $ #{LINECOOK_EXE} compile -Ilib '#{recipe_path}'
    }

    assert_str_equal %{
      echo abc
    }, content('recipe')
  end

  def test_compile_helper_searches_for_source_files_by_const_path_under_input_dirs
    prepare 'a/example/echo_a.erb', %{
      (str)
      --
      echo a <%= str %>
    }
    prepare 'b/example/echo_b.erb', %{
      (str)
      --
      echo b <%= str %>
    }
    recipe_path = prepare 'recipe.rb', %q{
      helpers 'example'
      echo_a 'abc'
      echo_b 'xyz'
    }

    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example -i '#{path('a')}' -i '#{path('b')}'
      #{path('lib/example.rb')}
      $ #{LINECOOK_EXE} compile -Ilib '#{recipe_path}'
    }

    assert_str_equal %{
      echo a abc
      echo b xyz
    }, content('recipe')
  end

  def test_compile_helper_has_sensible_error_for_no_sources_specified
    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example
      no sources specified
    }, :exitstatus => 1
  end

  def test_compile_helper_has_sensible_error_for_invalid_constant_name
    assert_script %{
      $ #{LINECOOK_EXE} compile-helper _Example
      invalid constant name: "_Example"
    }, :exitstatus => 1
  end

  def test_compile_helper_has_sensible_error_for_invalid_source_file_names
    source_file = prepare('-.rb', '')
    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example '#{source_file}'
      invalid source file: "#{source_file}" (invalid method name "-")
    }, :exitstatus => 1
  end

  def test_compile_helper_has_sensible_error_for_invalid_formats
    source_file = prepare('source_file.json', '')
    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example '#{source_file}'
      invalid source file: "#{source_file}" (unsupported format ".json")
    }, :exitstatus => 1
  end

  def test_compile_helper_has_sensible_error_for_invalid_section_formats
    source_file = prepare('_section_file.json', '')
    assert_script %{
      $ #{LINECOOK_EXE} compile-helper Example '#{source_file}'
      invalid source file: "#{source_file}" (unsupported section format ".json")
    }, :exitstatus => 1
  end

  #
  # run test
  #

  def test_run_runs_package_on_host_given_by_package_dir
    mark = rand(1000)
    path = prepare "#{host}/run", %{
      echo '#{mark}' > '#{remote_dir}/mark.txt'
    }, :mode => 0744
  
    Dir.chdir(user_dir) do
      assert_script %{
        $ #{LINECOOK_EXE} run -F '#{ssh_config_file}' -D '#{remote_dir}' '#{path(host)}' 2>/dev/null <&-
        $ ssh -F '#{ssh_config_file}' '#{host}' -- cat '#{remote_dir}/mark.txt'
        #{mark}
      }
    end
  end

  def test_run_allows_xtrace
    mark = rand(1000)
    path = prepare "#{host}/run", %{
      echo '#{mark}' > '#{remote_dir}/mark.txt'
    }, :mode => 0744

    Dir.chdir(user_dir) do
      with_env 'PS1' => '% ' do
        assert_script_match %{
          % #{LINECOOK_EXE} run -x -F '#{ssh_config_file}' -D '#{remote_dir}' '#{path(host)}' <&-
          $ sh :...:linecook_scp:...:
          + :....:
          $ sh :...:linecook_run:...:
          + :....:
          % ssh -F '#{ssh_config_file}' '#{host}' -- cat '#{remote_dir}/mark.txt'
          #{mark}
        }, :max_run_time => 2
      end
    end
  end

  def test_run_exits_with_status_1_for_failed_script
    path = prepare "#{host}/run", %{
      exit 8
    }, :mode => 0744

    Dir.chdir(user_dir) do
      assert_script %{
        $ #{LINECOOK_EXE} run -F '#{ssh_config_file}' -D '#{remote_dir}' '#{path(host)}' 2>/dev/null <&-
        non-zero exit status: 1
      }, :exitstatus => 1
    end
  end

  def test_run_exits_with_status_1_for_missing_run_script
    prepare_dir(host)

    Dir.chdir(user_dir) do
      assert_script %{
        $ #{LINECOOK_EXE} run -F '#{ssh_config_file}' -D '#{remote_dir}' '#{path(host)}' 2>/dev/null <&-
        non-zero exit status: 1
      }, :exitstatus => 1
    end
  end

  def test_run_can_use_remote_dirs_that_are_evaluated_on_the_host
    path = prepare "#{host}/run", %{
      cd "${0%/*}"
      [ "$(pwd)" = "/tmp/${HOME#/}" ]
    }, :mode => 0744

    Dir.chdir(user_dir) do
      assert_script %{
        $ #{LINECOOK_EXE} run -F '#{ssh_config_file}' -D '/tmp/${HOME#/}' '#{path(host)}' 2>/dev/null <&-
      }
    end
  end
end
