module Linecook
  # A proxy used to chain method calls back to a recipe.
  class Proxy < BasicObject
    def self.const_missing(name)
      ::Object.const_get(name)
    end

    attr_reader :target

    def initialize(recipe, target=nil)
      @recipe = recipe
      @target = target || StringIO.new
    end

    # Proxies to Recipe#_chain_
    def method_missing(*args, &block)
      @recipe._with_proxy_(self) do
        return @recipe._chain_proxy_? ? @recipe._chain_(*args, &block) : @recipe.__send__(*args, &block)
      end
    end

    # Returns an empty string, such that the proxy makes no text when it is
    # accidentally put into a target by a helper.
    def to_s
      @target.flush
      @target.rewind
      @target.read.strip
    end
  end
end