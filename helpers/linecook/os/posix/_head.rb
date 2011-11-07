require 'linecook/os/posix/variable'
require 'linecook/os/posix/utilities'
include Utilities

# Returns "$0", the current command name.
def command_name
  Variable.new(self, 0)
end

# Returns the command directory (ie the directory containing $0).
def command_dir
  "${0%/*}"
end

def set_package_dir(dir)
  export var('LINECOOK_PACKAGE_DIR', dir)
end

# Returns an expression that evaluates to the package dir.
def package_dir
  '${LINECOOK_PACKAGE_DIR:-$PWD}'
end

def target_path(target_name)
  File.join(package_dir, target_name)
end

# A hash of functions defined for self.
def functions
  @functions ||= {}
end

# Defines a function from the block.  The block content is indented and
# cleaned up some to make a nice function definition.
def function(name, method_name=name)
  str = capture { indent { yield(*signature(Proc.new.arity)) } }
  function = %{#{name}() {\n#{str.chomp("\n")}\n}}
  
  if function?(name)
    unless functions[name] == function
      Kernel.raise "function already defined: #{name.inspect}"
    end
  else
    functions[name] = function
    
    if method_name
      instance_eval %{
        def self.#{method_name}(*args)
          execute '#{method_name}', *args
          _chain_proxy_
        end
      }
    end
  end
  
  writeln function
  name
end

# Returns true if a function with the given name is defined.
def function?(name)
  functions.has_key?(name)
end

# Returns an array of positional variables for use as inputs to a function
# block.  Splat blocks are supported; the splat expression behaves like $*.
def signature(arity)
  variables = Array.new(arity.abs) {|i| Variable.new(self, i+1) }
  
  if arity < 0
    # This works for defaults...
    # $(shift 1; echo ${*:-NONE})
    # You can't do this:
    # ${$(shift 1; echo $*):-NONE}
    variables[-1] = "$(shift #{arity.abs - 1}; echo $*)"
  end
  
  variables
end

# Set a variable.
def var(name, value=nil)
  if Kernel.block_given?
    if value.nil?
      value = "$(\n#{capture(&Proc.new).strip}\n)"
    else
      Kernel.raise "value and block cannot both be specified"
    end
  end

  var = Variable.new(self, name)

  unless value.nil?
    var.value = value
  end

  var 
end

def trailer
  /(\s*(?:\ncheck_status.*?\n\s*)?)\z/
end
