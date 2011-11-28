require 'tempfile'
require 'stringio'

module Linecook
  class Package
    # The package environment
    attr_reader :env

    # A hash of global to self
    attr_reader :globals

    # A registry of (target_path, source_path) pairs recording what files are
    # included in the package.
    attr_reader :registry

    # A hash of (target_path, Hash) pairs identifing export options for a
    # target path.  See on_export.
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

    # Registers the target path with the source path and export options. The
    # source path should be the path to a file or directory to include.  To
    # make an empty file or directory use :file or :dir as the source_path.
    #
    # Raises an error if the target path is already registered.
    def register(target_path, source_path, options={})
      if registry.has_key?(target_path)
        raise "already registered: #{target_path.inspect}"
      end

      source_path = resolve_source_path(source_path)
      registry[target_path] = source_path
      on_export(target_path, options)

      source_path
    end

    # Removes a target path from the registry.  Returns the source path if one
    # was registered.
    def unregister(target_path)
      registry.delete(target_path)
      export_options.delete(target_path)
    end

    # Sets export options for the target path.  Available options (as
    # symbols):
    #
    #   move:: When set to true the source will be moved into place
    #          rather than copied (the default)
    #   mode:: Sets the mode of the target
    #
    # Unless specified, the values in default_export_options will be used.
    def on_export(target_path, options={})
      export_options[target_path] = default_export_options.merge(options)
    end

    # Generates a tempfile for the target path and registers it to self.
    # Returns the open tempfile.
    def add(target_path, options={})
      options  = {
        :move => true
      }.merge(options)

      # preserve a reference to tempfile so that it will not be unlinked
      # before it can be moved to the target path during export
      tempfile = Tempfile.new File.basename(target_path)
      options[:tempfile] = tempfile

      if block_given?
        begin
          yield tempfile
        ensure
          tempfile.close
        end
      end

      register target_path, tempfile.path, options
      tempfile
    end

    # Adds an empty dir, and all parent directories. Returns nil.
    def add_dir(target_path, options={})
      register target_path, :dir, options
    end

    alias rm unregister

    # Returns the source path registered to target path, or nil if the target
    # path is not registered.
    def source_path(target_path)
      registry[target_path]
    end

    # Returns an array of target paths that register the source_path.
    def target_paths(source_path)
      source = resolve_source_path(source_path)

      target_paths = []
      registry.each_pair do |target_path, current|
        if current == source
          target_paths << target_path
        end
      end
      target_paths
    end

    # Returns the content for the target path.  Returns nil if the target path
    # is not registered.
    def content(target_path, length=nil, offset=nil)
      source = source_path(target_path)
      source ? File.read(source, length, offset) : nil
    end

    # Increments target_path until an unregistered path is found and returns
    # the result in the format "target_path.count".
    def next_target_path(target_path='file')
      count = 0
      registry.each_key do |current|
        if current.index(target_path) == 0
          count += 1
        end
      end

      if count > 0
        target_path = "#{target_path}.#{count}"
      end

      target_path
    end

    def export(dir)
      registry.keys.sort.each do |target_path|
        export_path = File.join(dir, target_path)
        source_path = registry[target_path]
        options     = export_options[target_path] || default_export_options

        if source_path != export_path
          if File.exists?(export_path)
            if block_given?
              unless yield(source_path, export_path)
                next
              end
            else
              raise "already exists: #{export_path.inspect}"
            end
          end

          export_dir = File.dirname(export_path)
          FileUtils.mkdir_p(export_dir)

          case source_path
          when :file
            FileUtils.touch export_path
          when :dir
            FileUtils.mkdir export_path
          else
            if File.directory?(source_path)
              export_dir(source_path, export_path, options)
            else
              export_file(source_path, export_path, options)
            end
          end
        end

        if mode = options[:mode]
          FileUtils.chmod(mode, export_path)
        end

        registry[target_path] = export_path
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

    def export_dir(source_path, export_path, options) # :nodoc:
      if options[:move]
        FileUtils.mv(source_path, export_path)
      else
        FileUtils.cp_r(source_path, export_path)
      end
    end

    def export_file(source_path, export_path, options) # :nodoc:
      if options[:move]
        FileUtils.mv(source_path, export_path)
      else
        FileUtils.cp(source_path, export_path)
      end
    end
  end
end