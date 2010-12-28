require 'linecook/attributes'
require 'linecook/template'
require 'linecook/utils'
require 'tempfile'

module Linecook
  class Recipe < Template
    class << self
      def path_hash(dir='.')
        dir = File.expand_path(dir)
        
        Hash.new do |hash, relative_path|
          path = File.join(dir, relative_path.to_s)
          hash[relative_path] = File.exists?(path) ? path : nil
        end
      end
      
      def build(manifest, attrs)
        attrs['linecook'] ||= {
          'target_name' => 'linecook',
          'recipe_name' => 'linecook'
        }
        target_name = config['target_name'] or raise "no target name specified"
        recipe_name = config['recipe_name'] or raise "no recipe name specified"
        
        recipe = new(:target_name => target_name, :manifest => manifest, :attrs => attrs)
        recipe.evaluate(recipe_name)
        recipe.close
        recipe.registry
      end
    end
    
    include Utils
    
    alias target erbout
    
    attr_reader :target_name
    
    # A hash of (relative_path, source_path) pairs defining files available
    # for use by the recipe.  See source_path.
    attr_reader :manifest
    
    # A hash of (source_path, relative_path) pairs defining files created by
    # the recipe.  See target_path.
    attr_reader :registry
    
    def initialize(options={})
      @target_name = options[:target_name] || 'script'
      @manifest    = options[:manifest] || self.class.path_hash
      @registry    = options[:registry] || {}
      
      @erbout      = Tempfile.new(target_name)
      @attributes  = Attributes.new(options[:attrs] || {})
      
      @registry[erbout.path] = target_name
      @cache = [erbout]
    end
    
    def source_path(*relative_path)
      path = File.join(*relative_path)
      manifest[path] or raise "no such file: #{path.inspect}"
    end
    
    def target_path(source_path, basename=nil)
      source_path = File.expand_path(source_path)
      
      registry[source_path] ||= begin
        dirname = "#{target_name}.d"
        basename ||= File.basename(source_path)

        # generate a unique prefix for the basename
        count = 0
        registry.each_value do |path|
          if path.index(dirname) == 0
            count += 1
          end
        end

        File.join(dirname, "#{count}-#{basename}")
      end
      
      registry[source_path]
    end
    
    def target_file(name, content=nil)
      tempfile = Tempfile.new(name)
      tempfile << content if content
      yield(tempfile) if block_given?
      
      tempfile.close
      @cache << tempfile
      target_path(tempfile.path, name)
    end
    
    def attrs
      @attributes.current
    end
    
    def attributes(attributes_name)
      path = source_path('attributes', "#{attributes_name}.rb")
      
      @attributes.instance_eval(File.read(path), path)
      @attributes.reset(false)
      self
    end
    
    def helpers(helper_name)
      require underscore(helper_name)
      
      const = Object
      constants = camelize(helper_name).split(/::/)
      while name = constants.shift
        const = const.const_get(name)
      end
      
      extend const
    end
    
    def evaluate(recipe_name=nil)
      path = source_path('recipes', "#{recipe_name}.rb")
      instance_eval(File.read(path), path)
      self
    end
    
    def file_path(file_name)
      path = source_path('files', file_name)
      target_path path
    end
    
    def capture_path(name, &block)
      content = capture(false) { instance_eval(&block) }
      target_file(name, content)
    end
    
    def recipe_path(recipe_name)
      registry.each_pair do |key, value|
        if value == recipe_name
          return target_path(key)
        end
      end
      
      recipe = Recipe.new(
        :target_name => recipe_name, 
        :manifest => manifest,
        :registry => registry,
        :attrs    => @attributes.user_attrs
      )
      recipe.evaluate(recipe_name)
      @cache << recipe
      
      target_path recipe.target.path
    end
    
    def template_path(template_name, locals={})
      path = source_path('templates', "#{template_name}.erb")
      target_file template_name, Template.build(File.read(path), locals, path)
    end
    
    def close
      unless closed?
        @cache.each {|obj| obj.close }
        @registry.freeze
      end
      
      self
    end
  end
end
