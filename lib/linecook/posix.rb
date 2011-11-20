module Linecook
  class Proxy
    attr_reader :_recipe_
    attr_reader :_line_

    def initialize(_recipe_, _line_)
      @_recipe_ = _recipe_
      @_line_ = _line_
    end

    def _chain_to_(another)
      _line_.chain_to(another._line_)
    end
  end

  class Command < Line
    def as_prefix_to(b)
      content.rstrip
    end

    def as_suffix_to(a)
      " | #{content}"
    end
  end

  class Redirect < Line
    def as_prefix_to(b)
      content.rstrip
    end

    def as_suffix_to(a)
      " #{content}"
    end
  end

  class Heredoc < Redirect
    def initialize(word, body)
      super(word)
      append body # should be a line
    end
  end

  class CompoundCommand < Section
    def as_prefix_to(b)
      content.rstrip
    end

    def as_suffix_to(a)
      " | #{content}"
    end
  end

  class If < CompoundCommand
    attr_reader :condition
    attr_reader :body

    def initialize(condition, body)
      super "if", condition, "then", body, "fi"
      @condition = condition
      @body = body
    end

    def elif_(condition, body)
      body.append Elif.new(condition, body)
    end

    def else_(body)
      body.append Else.new(body)
    end
  end

  class Elif < Section
    attr_reader :condition
    attr_reader :body

    def initialize(condition, body)
      super "elif", condition, "then", body
      @condition = condition
      @body = body
    end
  end

  class Else < Section
    attr_reader :body

    def initialize(body)
      super "else", body
      @body = body
    end
  end
end