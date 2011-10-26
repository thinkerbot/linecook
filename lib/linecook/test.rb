require 'shell_test'
require 'linecook/recipe'

module Linecook
  module Test
    module ClassMethods

      # Nil host ends up falling through to the default as configured
      # in config/ssh
      def host
        @host ||= ENV['LINECOOK_TEST_HOST'] || name
      end

      def use_host(host)
        @host = host
      end
    end

    module ModuleMethods
      module_function

      def included(base)
        base.extend ClassMethods
        base.extend ModuleMethods unless base.kind_of?(Class)
        super
      end
    end

    extend ModuleMethods
    include ShellTest

    LINECOOK_DIR = File.expand_path('../../..', __FILE__)
    LINECOOK = File.join(LINECOOK_DIR, 'bin/linecook')

    def method_dir
      @host_method_dir ||= begin
        if test_host = ENV['LINECOOK_TEST_HOST']
          File.join(super, test_host)
        else
          super
        end
      end
    end

    def remote_dir
      method_dir[(user_dir.length + 1)..-1]
    end

    def ssh_config_file
      method_ssh_config_file = path('config/ssh')
      File.file?(method_ssh_config_file) ? method_ssh_config_file : 'config/ssh'
    end

    def setup_cookbook(project_dir=method_dir, *additional_project_dirs)
      @cookbook = Cookbook.new(project_dir, *additional_project_dirs)
    end

    def cookbook
      @cookbook ||= setup_cookbook
    end

    def setup_package(env={})
      @package = Package.new(env)
    end

    def package
      @package ||= setup_package
    end

    def use_helpers(*helpers)
      @helpers = helpers
    end

    def helpers
      @helpers ||= []
    end

    def use_host(host)
      @host = host
    end

    def host
      @host ||= self.class.host
    end

    def runlist
      @runlist ||= []
    end

    def setup_recipe(target_path=package.next_target_path('recipe'), &block)
      target = package.add(target_path, :mode => 0744)
      recipe = Recipe.new(package, cookbook, target)
      helpers.each {|helper| recipe.extend helper }

      recipe.instance_eval(&block) if block_given?
      runlist << target_path

      @recipe = recipe
    end

    def recipe
      @recipe ||= setup_recipe
    end

    def assert_recipe(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_equal expected, recipe._result_
      recipe
    end

    def assert_recipe_matches(expected, recipe=setup_recipe, &block)
      recipe.instance_eval(&block) if block_given?
      assert_str_match expected, recipe._result_
      recipe
    end

    def export_package(host=self.host)
      package_dir = path("packages/#{host}")
      package.export package_dir
      package_dir
    end

    def assert_package(expected, options={}, host=self.host)
      _assert_package outdent(expected), options, host
    end

    def _assert_package(expected, options={}, host=self.host)
      options = {
        'F' => ssh_config_file,
        'D' => remote_dir,
        'q' => true,
        'S' => runlist.join(',')
      }.merge(options)

      cmd = linecook('run', options, export_package(host))
      _assert_script %{$ #{cmd}\n#{expected}}, options
    end

    def assert_package_match(expected, options={}, host=self.host)
      options = {
        'F' => ssh_config_file,
        'D' => remote_dir,
        'q' => true,
        'S' => runlist.join(',')
      }.merge(options)

      cmd = linecook('run', options, export_package(host))
      _assert_script_match %{$ #{cmd}\n#{outdent(expected)}}, options
    end

    def assert_package_success
      assert_package '', :exitstatus => 0, :max_run_time => 2
    end

    def build_project(options={})
      options = {
        'L' => 'helpers',
        'C' => method_dir,
        'i' => path('packages'),
        'o' => path('packages')
      }.merge(options)

      Dir.chdir method_dir do
        cmd = linecook('build', options, *glob('recipes/*.rb'))
        _assert_script_match %{$ #{cmd}\n:....:}, options
      end
    end

    def assert_project(expected, options={}, *package_dirs)
      build_project(options)

      if package_dirs.empty?
        package_dirs = glob('packages/*').select {|path| File.directory?(path) }
      end

      options = {
        'F' => ssh_config_file,
        'D' => remote_dir,
        'q' => true
      }.merge(options)

      cmd = linecook('run', options, *package_dirs)
      _assert_script %{$ #{cmd}\n#{outdent(expected)}}, options
    end

    def linecook(cmd, options={}, *args)
      opts = []
      options.each_pair do |key, value|
        next unless key.kind_of?(String)
        key = key.to_s.gsub('_', '-')
        key = key.length == 1 ? "-#{key}" : "--#{key}"

        case value
        when true
          opts << key
        when nil, false
        else
          opts << "#{key} '#{value}'"
        end
      end

      args = args.collect! {|arg| "'#{arg}'" }

      cmd = [LINECOOK, cmd] + opts.sort + args
      cmd.join(' ')
    end
  end
end