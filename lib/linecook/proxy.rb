module Linecook
  # A proxy used to chain method calls back to a recipe.
  class Proxy < BasicObject
    def initialize(recipe)
      @recipe = recipe
    end

    # Invokes method via recipe.chain.
    def method_missing(*args, &block)
      @recipe.chain.__send__(*args, &block)
    end
  end
end