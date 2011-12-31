Makes a redirect statement.

(source, target, redirection='>')
--
  if chain?
    write " "
  end

  Redirect.new(source, target, redirection).write_to doc
  chain_proxy
  