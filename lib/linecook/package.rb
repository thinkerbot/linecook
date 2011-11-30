require 'tempfile'
require 'stringio'

module Linecook
  class Package
    # The package environment
    attr_reader :env

    # A hash of global to self
    attr_reader :globals

    # A registry of (path, source_path) pairs recording what files are
    # included in the package.
    attr_reader :registry

    # A hash of (path, Hash) pairs identifing export options for a package
    # file.  See on_export.
    attr_reader :export_options

    # A hash of default export options.
    attr_reader :default_export_options

    def initialize(env={})
      @env = env
      @globals = {}
      @registry = {}
      @export_options = {}
      @default_export_options  = {}
    end

    # Registers a file into the package with the specified export options. The
    # source path should be the path to a file or directory to include.  To
    # make an empty file or directory use :file or :dir as the source_path.
    #
    # Raises an error if a source is already registered at the path.
    def register(path, source_path, options={})
      if registry.has_key?(path)
        raise "already registered: #{path.inspect}"
      end

      source_path = resolve_source_path(source_path)
      registry[path] = source_path
      on_export(path, options)

      source_path
    end

    # Removes a file from the package.  Returns the source path if one was
    # registered.
    def unregister(path)
      registry.delete(path)
      export_options.delete(path)
    end

    # Sets export options for the package file.  Available options (as
    # symbols):
    #
    #   move:: When set to true the source will be moved into place
    #          rather than copied (the default)
    #   mode:: Sets the mode of the package file
    #
    # Unless specified, the values in default_export_options will be used.
    def on_export(path, options={})
      export_options[path] = default_export_options.merge(options)
    end

    # Generates a tempfile and registers it into the package at the specified
    # path. Returns the open tempfile.
    def add(path, options={})
      options  = {
        :move => true
      }.merge(options)

      # preserve a reference to tempfile in options so that it will not be
      # unlinked before it can be moved into the package during export
      tempfile = Tempfile.new File.basename(path)
      options[:tempfile] = tempfile

      if block_given?
        begin
          yield tempfile
        ensure
          tempfile.close
        end
      end

      register path, tempfile.path, options
      tempfile
    end

    # Adds an empty dir at path. Returns nil.
    def add_dir(path, options={})
      register path, :dir, options
    end

    alias rm unregister

    # Returns the source path registered at the path, or nil if no source is
    # registered.
    def source_path(path)
      registry[path]
    end

    # Returns an array of paths that the source path is registered to.
    def paths(source_path)
      source = resolve_source_path(source_path)

      paths = []
      registry.each_pair do |path, current|
        if current == source
          paths << path
        end
      end
      paths
    end

    # Returns the content to be added to the package at the path.  Returns nil
    # if nothing is registered.
    def content(path, length=nil, offset=nil)
      source = source_path(path)
      source ? File.read(source, length, offset) : nil
    end

    # Increments path until an unregistered path is found and returns the
    # result in the format "path.count".
    def next_path(path='file')
      count = 0
      registry.each_key do |current|
        if current.index(path) == 0
          count += 1
        end
      end

      if count > 0
        path = "#{path}.#{count}"
      end

      path
    end

    def export(dir)
      registry.keys.sort.each do |path|
        target_path = File.join(dir, path)
        source_path = registry[path]
        options     = export_options[path] || default_export_options

        if source_path != target_path
          if File.exists?(target_path)
            if block_given?
              unless yield(source_path, target_path)
                next
              end
            else
              raise "already exists: #{target_path.inspect}"
            end
          end

          target_dir = File.dirname(target_path)
          FileUtils.mkdir_p(target_dir)

          case source_path
          when :file
            FileUtils.touch target_path
          when :dir
            FileUtils.mkdir target_path
          else
            if File.directory?(source_path)
              export_dir(source_path, target_path, options)
            else
              export_file(source_path, target_path, options)
            end
          end
        end

        if mode = options[:mode]
          FileUtils.chmod(mode, target_path)
        end

        registry[path] = target_path
      end

      registry
    end

    private

    def resolve_source_path(source_path) # :nodoc:
      case source_path
      when :file, :dir then source_path
      else File.expand_path(source_path.to_s)
      end
    end

    def export_dir(source_path, target_path, options) # :nodoc:
      if options[:move]
        FileUtils.mv(source_path, target_path)
      else
        FileUtils.cp_r(source_path, target_path)
      end
    end

    def export_file(source_path, target_path, options) # :nodoc:
      if options[:move]
        FileUtils.mv(source_path, target_path)
      else
        FileUtils.cp(source_path, target_path)
      end
    end
  end
end