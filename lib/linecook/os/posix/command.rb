require 'linecook/line'
require 'linecook/os/posix/syntax'

module Linecook
  module Os
    module Posix
      class Command
        include Syntax

        attr_reader :name
        attr_reader :args
        attr_reader :options

        def initialize(name, args = [], options = {})
          @name = name
          @args = args
          @options = options
        end

        # Converts and returns the options hash as an array of arguments using
        # the following heuristics:
        #
        # * Prepend '--' to mulit-char keys and '-' to single-char keys
        #   (unless they already start with '-').
        # * Convert true values into '--key'
        # * Remove false/nil values
        # * For all other values add '--key', value
        #
        # In addition, key formatting is performed on non-string keys
        # (typically symbols) such that underscores are converted to dashes,
        # ie :some_key => 'some-key'.  Note that options are sorted, such that
        # short options appear after long options, and so should 'win' given
        # typical option processing.
        def option_args
          results = []

          options.keys.map do |key|
            unless key.kind_of?(String)
              key = key.to_s.gsub('_', '-')
            end

            unless key[0] == ?-
              prefix = key.length == 1 ? '-' : '--'
              key = "#{prefix}#{key}"
            end

            key
          end.sort.each do |key|
            value = options[key]

            case value
            when true
              results << key
            when false, nil
              next
            else
              results << key
              results << value
            end
          end

          results
        end

        def write_to(doc, context={})
          doc.write quote(name)

          (option_args + args).each do |arg|
            if arg.respond_to?(:write_to)
              arg.write_to doc, context
            else
              doc.write " #{quote(arg)}"
            end
          end
        end

        def to_s
          write_to(Document.new).to_s
        end
      end
    end
  end
end