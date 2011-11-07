module Linecook
  module Os
    module Posix
      module Utils
        module_function

        # Encloses the arg in quotes, unless already quoted (see quoted?).
        def quote(str)
          quoted?(str) ? str : "\"#{str}\""
        end

        # Returns true if the str is quoted (either by quotes or apostrophes).
        def quoted?(str)
          str =~ /\A".*"\z/ || str =~ /\A'.*'\z/ ? true : false
        end

        # Encloses the arg in quotes unless the arg is an option or already quoted
        # (see option? and quoted?).
        def option_quote(str)
          option?(str) ? str : quote(str)
        end

        # Returns true if the str is an option (ie it begins with - or +).
        def option?(str)
          c = str[0]
          c == ?- || c == ?+
        end

        # Formats a command line command.  Arguments are quoted. If the last arg is a
        # hash, then it will be formatted into options using format_options and
        # prepended to args.
        def command_str(command, *args)
          opts = args.last.kind_of?(Hash) ? args.pop : {}
          args.compact!
          args.collect! {|arg| option_quote(arg.to_s) }

          args = options_str(opts) + args
          args.unshift(command)
          args.join(' ')
        end

        # Formats a hash key-value string into command line options using the
        # following heuristics:
        #
        # * Prepend '--' to mulit-char keys and '-' to single-char keys (unless they
        #   already start with '-').
        # * For true values return the '--key'
        # * For false/nil values return nothing
        # * For all other values, quote (unless already quoted) and return '--key
        #  "value"'
        #
        # In addition, key formatting is performed on non-string keys (typically
        # symbols) such that underscores are converted to dashes, ie :some_key =>
        # 'some-key'.  Note that options are sorted, such that short options appear
        # after long options, and so should 'win' given typical option processing.
        def options_str(opts)
          options = []

          opts.each do |(key, value)|
            unless key.kind_of?(String)
              key = key.to_s.gsub('_', '-')
            end

            unless key[0] == ?-
              prefix = key.length == 1 ? '-' : '--'
              key = "#{prefix}#{key}"
            end

            case value
            when true
              options << key
            when false, nil
              next
            else
              options << "#{key} #{quote(value.to_s)}"
            end
          end

          options.sort
        end
      end
    end
  end
end