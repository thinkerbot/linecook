Executes a command and checks the output status. Quotes all non-option args
that aren't already quoted. Accepts a trailing hash which will be transformed
into command line options.

(command, *args)
--
  args = args.compact
  options = args.last.kind_of?(Hash) ? args.pop : {}
  writeln Command.new(command, args, options)
  chain_proxy
