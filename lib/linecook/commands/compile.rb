require 'fileutils'
require 'linecook/recipe'
require 'linecook/commands/compile_helper'
require 'yaml'
require 'csv'

module Linecook
  module Commands
    # ::desc compile recipes
    #
    # Compiles a list of recipes into a single package and exports the result
    # to the working directory.  The recipes are added to the package at their
    # relative path, minus their extname.
    #
    # For example:
    #
    #   $ echo "write 'echo hello world'" > recipe.rb 
    #   $ linecook compile recipe.rb
    #   $ sh recipe
    #   hello world
    #
    # Providing '-' as a recipe will cause stdin to be compiled as a recipe to
    # stdout.
    class Compile < Command
      class << self
        def parse(argv=ARGV)
          super(argv) do |options|
            options.on('-I DIRECTORY', 'prepend to LOAD_PATH') do |path|
              $LOAD_PATH.unshift File.expand_path(path)
            end

            options.on('-r LIBRARY', 'require the library') do |path|
              require(path)
            end

            options.on('-G GEMNAME', 'add gem to cookbook path', :option_type => :list) do |name|
              specs = Gem.source_index.find_name(name)
              if specs.empty?
                raise CommandError, "could not find gem: #{name.inspect}"
              end
              (options[:cookbook_path] ||= []) << specs.first.full_gem_path
            end

            options.on('-g', '--gems', 'add latest cookbook gems') do |name|
              (options[:cookbook_path] ||= []).concat cookbook_gem_paths
            end

            options.on('-c', '--common', 'use common flags') do
              set_common_options(options)
            end

            if block_given?
              yield(options)
            end
          end
        end

        def set_common_options(options)
          cookbook_path = (options[:cookbook_path] ||= [])
          cookbook_path << '.'
          cookbook_path.concat cookbook_gem_paths
          (options[:helper_dirs] ||= []) << 'helpers'
          options
        end

        def cookbook_gem_paths(latest=true)
          Cookbook.gemspecs(latest).collect do |gemspec|
            gemspec.full_gem_path
          end
        end

        def gemspecs(latest=true)
          return [] unless Object.const_defined?(:Gem)

          index = Gem.source_index
          specs = latest ? index.latest_specs : index.gems.values

          specs.select do |spec|
            cookbook_file = File.expand_path(default_file_name, spec.full_gem_path)
            File.exists?(cookbook_file)
          end
        end
      end

      config :cookbook_path, [], :delimiter => ':'     # -C PATH : cookbook path
      config :helper_dirs, []                          # -L DIRECTORY : compile helpers
      config :package_file, nil                        # -p PATH : package config file
      config :input_dir, '.', :writer => :input_dir=   # -i DIRECTORY : the input dir
      config :output_dir, '.', :writer => :output_dir= # -o DIRECTORY : the output dir
      config :force, false                             # -f, --force : overwrite existing

      def input_dir=(input)
        @input_dir = File.expand_path(input)
      end

      def output_dir=(input)
        @output_dir = File.expand_path(input)
      end

      def process(*recipes)
        helper_dirs.each do |helper_dir|
          compile_helpers(helper_dir)
        end

        package  = Package.new(load_env(package_file))
        cookbook = Cookbook.new(*cookbook_path)
        stdout   = StringIO.new

        recipes.each do |recipe_path|
          recipe = Recipe.new(package, cookbook)

          if recipe_path == '-'
            recipe.instance_eval $stdin.read, 'stdin'
            stdout.print recipe
          else
            recipe_path = File.expand_path(recipe_path)
            recipe.instance_eval File.read(recipe_path), recipe_path

            target_path = relative_path(input_dir, recipe_path).chomp('.rb')
            package.add(target_path) {|io| io << recipe }
          end
        end

        package.export(output_dir) do |src, dest|
          unless force
            raise CommandError, "already exists: #{dest.inspect}"
          end

          FileUtils.rm_rf(dest)
          true
        end

        # print to $stdout after export to ensure files will be available
        $stdout << stdout.string
      end

      def relative_path(dir, path)
        if path.index(dir) == 0 && path != dir
          path[dir.length + 1, path.length - dir.length]
        else
          File.basename(path)
        end
      end

      def load_env(package_file)
        env = package_file && File.exists?(package_file) ? YAML.load_file(package_file) : nil
        env.nil? ? {} : env
      end

      def glob_helpers(helper_dir)
        sources = {}
        helpers = []

        Dir.glob("#{helper_dir}/*/**/*").each do |source_file|
          next if File.directory?(source_file)
          (sources[File.dirname(source_file)] ||= []) << source_file
        end

        sources.each_pair do |dir, source_files|
          name = dir[(helper_dir.length + 1)..-1]
          helpers << [name, source_files]
        end

        helpers.sort_by {|name, source_files| name }
      end

      def compile_helpers(helper_dir)
        compiler = CompileHelper.new(
          :force => force,
          :quiet => true
        )

        helpers = glob_helpers(helper_dir)
        helpers.each do |(name, sources)|
          compiler.process(name, *sources)
        end

        $LOAD_PATH.unshift compiler.output_dir
      end
    end
  end
end