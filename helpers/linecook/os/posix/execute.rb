Executes a command and checks the output status. Quotes all non-option args
that aren't already quoted. Accepts a trailing hash which will be transformed
into command line options.

(command, *args)
--
  if chain?
    write " | "
  else
    doc.append_line
  end

  args = args.compact
  options = args.last.kind_of?(Hash) ? args.pop : {}
  Command.new(command, args, options).write_to doc

  chain_proxy
