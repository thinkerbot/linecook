require 'erb'
require 'tilt'
require 'linecook/attributes'
require 'linecook/cookbook'
require 'linecook/document'
require 'linecook/package'
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
  class Recipe < Context
    # The recipe Package
    attr_reader :_package_

    # The recipe Cookbook
    attr_reader :_cookbook_

    # A hash just for self
    attr_reader :_locals_

    # The recipe Document
    attr_reader :_doc_

    def initialize(package = Package.new, cookbook = Cookbook.new, doc = Document.new)
      @_package_ = package
      @_cookbook_ = cookbook
      @_locals_ = {}
      @_doc_ = doc

      @attributes = {}
      @attrs = nil

      if Kernel.block_given?
        instance_eval(&Proc.new)
      end
    end

    # Returns the package globals.
    def _globals_
      _package_.globals
    end

    # Initializes clones created by _clone_ by passing forward all state,
    # including local data and attributes.
    def _initialize_clone_(orig)
      super
      @_package_ = orig._package_
      @_cookbook_ = orig._cookbook_
      @_locals_ = orig._locals_
      @_doc_ = orig._doc_

      @attributes = orig.attributes
      @attrs = nil
    end

    # Initializes children created by _beget_ by setting _doc_ to a new
    # Document.  Note that the child shares the same locals and attributes as
    # the parent, and so can (un)intentionally cause changes in the parent.
    def _initialize_child_(orig)
      super
      @_doc_ = Document.new
    end

    # Returns a child of self with it's own Document.  Writes str to the
    # child, and evaluates the block in the context of the child, if given.
    def _(str=nil, &block)
      child = _beget_
      child.write str if str
      child.instance_eval(&block) if block
      child
    end

    # Captures output to the doc for the duration of a block. Returns the doc.
    def _capture_(doc = Document.new)
      current = @_doc_
      begin
        @_doc_ = doc
        yield
      ensure
        @_doc_ = current
      end
      doc
    end

    # Returns the formatted contents of _doc_.
    def _result_
      _doc_.to_s
    end

    # Loads the specified attributes file and merges the results into attrs. A
    # block may be given to specify attrs as well; it will be evaluated in the
    # context of an Attributes instance.
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
            # Don't use Kernel because the may evade RubyGems
            Utils.__send__(:require, Utils.underscore(helper_name))
            Utils.constantize(module_name)
          end
        end
        helper.__send__(:extend_object, self)
      end
      self
    end

    # Captures and returns the formatted output of the block as a string.
    def capture
      _capture_ { yield }.to_s
    end

    # Writes input to _doc_ using 'write'.  Returns self.
    def write(input)
      _doc_.write input
      self
    end

    # Writes input to _doc_ using 'writeln'.  Returns self.
    def writeln(input=nil)
      _doc_.writeln input
      self
    end

    # Indents n levels for the duration of the block.
    def indent(n=1)
      _doc_.with(:indent => n) do
        yield
      end
    end

    # Outdents for the duration of the block.  A negative number can be
    # provided to outdent n levels.
    def outdent(n=nil)
      _doc_.with(:indent => n) do
        yield
      end
    end
  end
end