require 'linecook/context'

module Linecook
  # A proxy used to chain method calls back to a recipe.
  class Proxy < Context
    attr_reader :_recipe_
    attr_reader :_str_
    attr_reader :_pos_

    def initialize(_recipe_, _str_=nil)
      if Kernel.block_given?
        _str_ = _recipe_.capture(&Proc.new)
      end

      @_recipe_ = _recipe_
      @_pos_ = _recipe_.target.pos
      @_str_ = _str_

      if _str_
        _recipe_.write _str_
      end
    end

    def _chain_to_(another)
      # s......e-----s......e-----
      # s......e | s......e-----
      #
      # * check writes but does not move end pos
      # * can be accomplished by override mm and super + write
      # * raise error if another command attempts to chain
      #

      pos = another._pos_ + another._str_.rstrip.length
      target = _recipe_.target
      target.pos = pos
      target.truncate pos

      chain_str = _chain_str_
      target.write _chain_str_
      @_pos_ = pos + (chain_str.length - _str_.length)
    end

    def _chain_str_
      _str_
    end

    def method_missing(*args, &block)
      result = _recipe_.__send__(*args, &block)

      if Proxy === result
        result._chain_to_(self)
      end

      _recipe_ == result ? self : result
    end
  end
end