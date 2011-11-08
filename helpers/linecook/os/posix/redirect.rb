Makes a redirect statement.

(source, target, redirection='>')
--
  source = source.nil? || source.kind_of?(Fixnum) ? source : "#{source} "
  target = target.nil? || target.kind_of?(Fixnum) ? "&#{target}" : " #{target}"
  Redirect.new self, "#{source}#{redirection}#{target}\n"
  