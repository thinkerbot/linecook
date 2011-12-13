require 'linecook/line'
require 'linecook/os/posix/syntax'

module Linecook
  module Os
    module Posix
      class Redirect
        include Syntax

        attr_reader :source
        attr_reader :target
        attr_reader :redirection

        def initialize(source, target, redirection='>')
          @source = source
          @target = target
          @redirection = redirection
        end

        def write_to(line = Line.new)
          line.write to_s
          line
        end

        def chain_to(line = Line.new)
          line.chain " ", to_s
          line
        end

        def to_s
          source_str = source.nil? || source.kind_of?(Fixnum) ? source : "#{source} "
          target_str = target.nil? || target.kind_of?(Fixnum) ? "&#{target}" : " #{quote target}"

          "#{source_str}#{redirection}#{target_str}"
        end
      end
    end
  end
end