Executes a command and checks the output status. Quotes all non-option args
that aren't already quoted. Accepts a trailing hash which will be transformed
into command line options.

(command, *args)
--
  Command.new self do
    writeln Utils.command_str(command, *args)
  end
