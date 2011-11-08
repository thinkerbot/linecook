require 'linecook/proxy'

module Linecook
  module Os
    module Posix
      class Redirect < Proxy
        def _chain_str_
          " #{_str_}"
        end

        def _chain_to_(another)
          super
          _recipe_.check_status
        end
      end
    end
  end
end