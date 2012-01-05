require 'erb'
require 'tilt'
require 'linecook/attributes'
require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/resource'
require 'linecook/utils'
require 'linecook/proxy'

module Linecook
  # Recipe is the context in which recipes are evaluated (literally).  Recipe
  # uses compiled ERB snippets to build text using method calls. For example:
  #
  #   module Helper
  #     # This is an ERB template compiled to write to a Recipe.
  #     #
  #     #   compiler = ERB::Compiler.new('<>')
  #     #   compiler.put_cmd = "write"
  #     #   compiler.insert_cmd = "write"
  #     #   compiler.compile("echo '<%= args.join(' ') %>'\n")
  #     #
  #     def echo(*args)
  #       write "echo '"; write(( args.join(' ') ).to_s); write "'\n"
  #     end
  #   end
  #
  #   recipe = Recipe.new do
  #     _extend_ Helper
  #     echo 'a', 'b c'
  #     echo 'X Y'.downcase, :z
  #   end
  #
  #   "\n" + recipe.to_s
  #   # => %{
  #   # echo 'a b c'
  #   # echo 'x y z'
  #   # }
  #
  class Recipe < BasicObject
    include Resource

    # The recipe Proxy
    attr_reader :_proxy_

    # The recipe Package
    attr_reader :_package_

    # The recipe Cookbook
    attr_reader :_cookbook_

    # The target recieving writes
    attr_reader :target

    def initialize(package = Package.new, cookbook = Cookbook.new, target = "")
      @_proxy_    = Proxy.new(self)
      @_package_  = package
      @_cookbook_ = cookbook
      @target     = target
      @chain      = false
      @attributes = {}
      @attrs      = nil

      if Kernel.block_given?
        instance_eval(&Proc.new)
      end
    end

    # Overridden to look up constants as normal.
    def self.const_missing(name)
      ::Object.const_get(name)
    end

    # Returns the singleton class for self.  Used by clone to access modules
    # included in self (ex via _extend_).
    def _singleton_class_
      class << self
        SINGLETON_CLASS = self
        def _singleton_class_
          SINGLETON_CLASS
        end
      end

      # this and future calls go to the _singleton_class_ as defined above.
      _singleton_class_
    end

    # Returns the class for self.
    def _class_
      _singleton_class_.superclass
    end

    # Extends self with the module.
    def _extend_(mod)
      mod.__send__(:extend_object, self)
    end

    # Callback to initialize a clone of self. Passes forward all state,
    # including local data and attributes.
    def _initialize_clone_(orig)
      @_proxy_    = Proxy.new(self)
      @_package_  = orig._package_
      @_cookbook_ = orig._cookbook_
      @target     = orig.target
      @chain      = orig.chain?
      @attributes = orig.attributes
      @attrs      = nil
    end

    # Returns a clone of self, kind of like Object#clone.
    #
    # Note that unlike Object.clone this currently does not carry forward
    # tainted/frozen state, nor can it carry forward singleton methods.
    # Modules and internal state only.
    def _clone_
      clone = _class_.allocate
      clone._initialize_clone_(self)
      _singleton_class_.included_modules.each {|mod| clone._extend_ mod }
      clone
    end

    # Callback to initialize children created by _beget_.  Sets a new target
    # by calling dup.clear on the original target, and unchains.  Note that
    # the child shares the same attributes as the parent, and so can
    # (un)intentionally cause changes in the parent.
    def _initialize_child_(orig)
      @target = orig.target.dup.clear
      unchain
    end

    # Returns a clone of self created by _clone_, but also calls
    # _initialize_child_ on the clone.
    def _beget_
      clone = _clone_
      clone._initialize_child_(self)
      clone
    end

    # Returns a child of self with a new target.  Writes str to the child, and
    # evaluates the block in the context of the child, if given.
    def _(str=nil, &block)
      child = _beget_
      child.write str if str
      child.instance_eval(&block) if block
      child
    end

    # Loads the specified attributes file and merges the results into attrs. A
    # block may be given to specify attrs as well; it will be evaluated in the
    # context of an Attributes instance.
    #
    # Returns a hash representing all attributes loaded thusfar (specifically
    # attrs prior to merging in the package env). The attributes hash should
    # be treated as if it were read-only.
    def attributes(source_name=nil, &block)
      if source_name || block
        attributes = Attributes.new

        if source_name
          if source_path = _cookbook_.find(:attributes, source_name, attributes.load_attrs_extnames)
            attributes.load_attrs(source_path)
          end
        end

        if block
          attributes.instance_eval(&block)
        end

        @attributes = Utils.deep_merge(@attributes, attributes.to_hash)
        @attrs = nil
      end

      @attributes
    end

    # Returns the package env merged over any attrs specified by attributes.
    #
    # The attrs hash should be treated as if it were read-only because changes
    # could alter the package env and thereby spill over into other recipes.
    def attrs
      @attrs ||= Utils.deep_merge(@attributes, _package_.env)
    end

    # Looks up and extends self with the specified helper(s).
    def helpers(*helper_names)
      helper_names.each do |helper|
        unless helper.respond_to?(:extend_object)
          helper_name = helper
          module_name = Utils.camelize(helper_name)

          helper = Utils.constantize(module_name) do
            # Don't use Kernel because that may evade RubyGems
            Utils.__send__(:require, Utils.underscore(helper_name))
            Utils.constantize(module_name)
          end
        end
        helper.__send__(:extend_object, self)
      end
      self
    end

    # Captures writes during the block to a new target.  Returns the target.
    def capture(target = "")
      current = @target
      begin
        @target = target
        yield
      ensure
        @target = current
      end
      target
    end

    # Writes input to target using `<<`. Stringifies input using to_s. Returns
    # self.
    def write(input)
      target << input.to_s
      self
    end

    # Writes input to self, writes a newline, and returns last.
    def writeln(input=nil)
      write input
      write "\n"
      self
    end

    # Looks up a template in _cookbook_ and renders it.
    def render(template_name, locals=attrs)
      file = _cookbook_.find(:templates, template_name, ['.erb'])
      Tilt.new(file).render(Object.new, locals)
    end

    # Causes chain? to return true.  Returns self.
    def chain
      @chain = true
      self
    end

    # Causes chain? to return false.  Returns self.
    def unchain
      @chain = false
      self
    end

    # Returns the proxy.  Unchains first to ensure that if the proxy is not
    # called, then the previous chain is stopped.
    def chain_proxy
      unchain
      _proxy_
    end

    # Returns true as per chain/unchain.
    def chain?
      @chain
    end

    # Returns target.to_s.
    def to_s
      target.to_s
    end
  end
end