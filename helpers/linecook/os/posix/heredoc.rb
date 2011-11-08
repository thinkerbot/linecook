Makes a heredoc statement surrounding the contents of the block.  Options:

  delimiter   the delimiter used, by default HEREDOC_n where n increments
  outdent     add '-' before the delimiter
  quote       quotes the delimiter

(options={})
--
  unless options.kind_of?(Hash)
    options = {:delimiter => options}
  end
  outdent = options[:outdent] ? '-' : ' '
  delimiter = options[:delimiter] || begin
    @heredoc_count ||= -1
    "HEREDOC_#{@heredoc_count += 1}"
  end

  Redirect.new(self) do
    write "<<#{outdent}#{options[:quote] ? "\"#{delimiter}\"" : delimiter}"
    outdent(" # :#{delimiter}:") do
      writeln
      yield
      write delimiter
    end
    writeln
  end

