module Linecook
  module Os
    module Posix
      class Variable
        class << self
          def transform(name, operation)
            signature = operation.scan(/\#\{(.*?)\}/).flatten
            signature.delete('varname')

            class_eval %{
              def #{name}!(#{signature.join(',')})
                self.value = "#{operation}"
              end

              def #{name}(#{signature.join(',')})
                beget "#{operation}"
              end
            }
          end

          def operation(name, operation)
            class_eval %{
              def #{name}(another)
                beget "#{operation}"
              end
            }
          end

          def test(name, operation="-#{name}")
            class_eval %{
              def #{name}(another)
                recipe._test %{"\#{self}" #{operation} "\#{another}"}
              end
            }
          end

          def check(name, operation)
            class_eval %{
              def #{name}?
                recipe._test %{#{operation} "\#{self}"}
              end
            }
          end
        end

        attr_reader :recipe
        attr_reader :varname
        attr_accessor :default

        def initialize(recipe, varname, default=nil)
          @varname = varname.to_s
          @default = default
          @recipe  = recipe
        end

        def beget(value)
          var = Variable.new recipe, recipe._package_.next_variable_name(varname.sub(/\d+\z/, ''))
          var.value = value
          var
        end

        def value=(str)
          recipe.writeln "#{varname}=#{recipe.quote(str)}"
        end

        transform 'lstrip', '${#{varname}#{pattern}}'
        transform 'llstrip', '${#{varname}##{pattern}}'
        transform 'rstrip', '${#{varname}%{pattern}}'
        transform 'rrstrip', '${#{varname}%%{pattern}}'
        transform 'sub', '${#{varname}/#{pattern}/#{replacement}}'
        transform 'gsub', '${#{varname}//#{pattern}/#{replacement}}'
        transform 'length', '${##{varname}}'
        operation '+', '$(( #{self} + #{another} ))'

        def substring(offset, length=nil)
          length ? "${#{varname}:#{offset}:#{length}}": "${#{varname}:#{offset}}"
        end

        test 'eq'
        test 'ne'
        test 'gt'
        test 'lt'
        test '==', '='
        test '>', '>'
        test '<', '<'
        check 'null', '-z'
        check 'not_null', '-n'

        def !=(another)
          "! #{self == another}"
        end

        def to_s
          default.nil? ? "${#{varname}}" : "${#{varname}:-#{default}}"
        end
      end
    end
  end
end