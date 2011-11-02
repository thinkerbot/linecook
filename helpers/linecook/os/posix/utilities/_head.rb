# Set the export attribute for variables.
# {[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_22]
def export(key, value=nil)
  if block_given?
    if value.nil?
      value = "$(\n#{capture(&Proc.new).strip}\n)"
    else
      raise "value and block cannot both be specified"
    end
  end

  if value.nil?
    writeln "export #{key}"
  else
    writeln "export #{key}=#{quote(value)}"
  end

  return Variable.new(key)
end