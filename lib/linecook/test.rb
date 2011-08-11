require 'shell_test'
require 'linecook/recipe'

module Linecook
  module Test
    module ClassMethods
      def host
        @host ||= ENV['LINECOOK_TEST_HOST'] || name
      end

      def use_host(host)
        @host = host
      end

      def only_hosts(*patterns)
        patterns.collect! do |pattern|
          pattern.kind_of?(Regexp) ? pattern : /\A#{pattern}\z/
        end

        unless patterns.any? {|pattern| host =~ pattern }
          skip_test "not for host (#{host})"
        end
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

    def setup_recipe(target_path=package.next_target_path, &block)
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

    # def build_package(host=self.host)
    #   package_dir = path("packages/#{host}")
    #
    #   package.build
    #   package.export package_dir
    #
    #   package_dir
    # end

    def run_package(options={}, host=self.host)
      options['remote_script'] ||= runlist.join(',')

      package_dir = path("packages/#{host}")
      package.export package_dir

      run_project options, package_dir
    end

    def compile_project(options={})
      options = {
        'H' => 'helpers',
        'C' => method_dir,
        'o' => path('packages'),
        'x' => true
      }.merge(options)

      Dir.chdir(method_dir) do
        glob('recipes/*.rb').each do |recipe|
          name = File.basename(recipe).chomp('.rb')
          options['P'] = path("packages/#{name}.yml")
          linecook('compile', options, recipe)
        end
      end
    end

    # # pick up user dir as a gem... bundler!
    def run_project(options={}, *package_dirs)
      if package_dirs.empty?
        package_dirs = glob('packages/*').select {|path| File.directory?(path) }
      end

      options = {
        'ssh_config_file' => ssh_config_file,
        'remote_dir'      => remote_dir,
        'quiet'           => true
      }.merge(options)

      linecook('run', options, *package_dirs)
    end

    def linecook(cmd, options={}, *args)
      stdout = prepare("log/#{cmd}.out")
      stderr = prepare("log/#{cmd}.err")

      command = "#{linecook_cmd(cmd, options, *args)} 2> '#{stderr}' > '#{stdout}'"
      system(command)

      [File.read(stdout), "$ #{command}\n#{File.read(stderr)}"]
    end

    def linecook_cmd(cmd, options={}, *args)
      opts = []
      options.each_pair do |key, value|
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