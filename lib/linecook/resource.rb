module Linecook
  module Resource
    attr_reader :package_path
    attr_reader :package_opts

    def register_as(path, options={})
      @package_path = path
      @package_opts = options
      self
    end

    def register_to(package)
      path    = package_path || package.next_path("resource")
      options = package_opts || {}
      package.add(path, options) {|io| io << to_s }
    end
  end
end
