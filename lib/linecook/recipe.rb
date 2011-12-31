require 'erb'
require 'tilt'
require 'linecook/attributes'
require 'linecook/cookbook'
require 'linecook/document'
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
  #   recipe  = Recipe.new do
  #     _extend_ Helper
  #     echo 'a', 'b c'
  #     echo 'X Y'.downcase, :z
  #   end
  #
  #   "\n" + recipe._result_
  #   # => %{
  #   # echo 'a b c'
  #   # echo 'x y z'
  #   # }
  #
  class Recipe < BasicObject
    include Resource

    # The recipe Package
    attr_reader :_package_

    # The recipe Cookbook
    attr_reader :_cookbook_

    # The recipe Document
    attr_reader :doc

    # The recipe Proxy
    attr_reader :_proxy_

    # The recipe locals hash.
    attr_reader :locals

    def initialize(package = Package.new, cookbook = Cookbook.new)
      @_package_  = package
      @_cookbook_ = cookbook
      @_proxy_ = Proxy.new(self)

      @doc        = Document.new
      @chain      = false
      @attributes = {}
      @attrs = nil
      @locals = {}

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
      @_package_  = orig._package_
      @_cookbook_ = orig._cookbook_
      @_proxy_    = Proxy.new(self)

      @doc        = orig.doc
      @chain      = orig.chain?
      @attributes = orig.attributes
      @attrs      = nil
      @locals = orig.locals
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

    # Initializes children created by _beget_ by setting doc to a new
    # Document.  Note that the child shares the same locals and attributes as
    # the parent, and so can (un)intentionally cause changes in the parent.
    def _initialize_child_(orig)
      @doc   = Document.new
      @chain = false
    end

    # Returns a clone of self created by _clone_, but also calls
    # _initialize_child_ on the clone.
    def _beget_
      clone = _clone_
      clone._initialize_child_(self)
      clone
    end

    # Returns a child of self with it's own Document.  Writes str to the
    # child, and evaluates the block in the context of the child, if given.
    def _(str=nil, &block)
      child = _beget_
      child.write str if str
      child.instance_eval(&block) if block
      child
    end

    # Returns the package globals hash.
    def globals
      _package_.globals
    end

    # Loads the specified attributes file and merges the results into attrs. A
    # block may be given to specify attrs as well; it will be evaluated in the
    # context of an Attributes instance.
    #
    # Returns a hash representing all attributes loaded thusfar (specifically
    # attrs prior to merging in the package env). The attributes hash should
    # be treated as if it were read-only. Use locals or globals instead.
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
    # Use locals or globals instead.
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

    # Captures and returns the formatted output of the block as a string.
    def capture(doc = Document.new)
      current = @doc
      begin
        @doc = doc
        yield
      ensure
        @doc = current
      end
      doc
    end

    # Writes input to doc using `write`.  If chaining then write using
    # `chain` and then turn off. Returns self.
    def write(input)
      unchain

      if input.respond_to?(:write_to)
        input.write_to doc
      else
        doc.write input
      end

      self
    end

    # Writes input to self, writes a newline, and returns last.
    def writeln(input=nil)
      write input
      write "\n"
      self
    end

    # Indents n levels for the duration of the block.
    def indent(n=1)
      doc.with(:indent => n) do
        yield
      end
    end

    # Outdents for the duration of the block.  A negative number can be
    # provided to outdent n levels.
    def outdent(n=nil)
      doc.with(:indent => n) do
        yield
      end
    end

    # Causes chain? to return true.  Returns self.
    def chain
      @chain = true
      self
    end

    # Causes chain? to return false.  Returns self.
    def unchain
      unless @chain
        doc.set_marks doc.last
      end

      @chain = false
      self
    end

    # Returns true as per chain/unchain.
    def chain?
      @chain
    end

    # Returns the proxy.  Unchains first to ensure that if the proxy is not
    # called, then the previous chain is stopped.
    def chain_proxy
      _proxy_
    end

    # Returns the formatted contents of doc.
    def to_s
      doc.to_s
    end
  end
end