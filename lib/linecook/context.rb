module Linecook
  class Context < BasicObject
    # Overridden to look up constants as normal.
    def self.const_missing(name)
      ::Object.const_get(name)
    end

    # Returns the singleton class for self.
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

    # Callback to initialize a clone of self, based upon the original object.
    def _initialize_clone_(orig)
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

    # Callback to initialize a child of self created by _beget_.
    def _initialize_child_(orig)
    end

    # Returns a clone of self created by _clone_, but also calls
    # _initialize_child_ on the clone.
    def _beget_
      clone._initialize_child_(self)
      clone
    end
  end
end
