Change the working directory, for the duration of a block if given.
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/cd.html]

(directory=nil, options={})
--
  if block_given?
    var = _package_.next_variable_name('OLDPWD_')
    write %{#{var}=$(pwd); }
    execute 'cd', directory, options
    indent(&Proc.new)
    execute 'cd', "$#{var}"
  else
    execute 'cd', directory, options
  end