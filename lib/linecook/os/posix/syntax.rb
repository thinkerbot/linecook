module Linecook
  module Os
    module Posix
      module Syntax
        module_function

        # Section 2.2 Quoting
        SPECIAL_CHARS = %w{ | & ; < > ( ) $ ` \\ " ' } + [" ", "\t", "\n"] + %w{ * ? [ # ~ = % }
        SPECIAL_CHARS_REGEXP = Regexp.union(*SPECIAL_CHARS)

        # Returns true if str includes any of the special chars.
        def needs_quote?(str)
          str =~ SPECIAL_CHARS_REGEXP ? true : false
        end

        # Quotes str if str is unquoted and has any special chars.
        def quote(str)
          !quoted?(str) && needs_quote?(str) ? %{"#{str.gsub(/"/, '\"')}"} : str
        end
        
        # Returns true if the str is quoted (either by quotes or apostrophes).
        def quoted?(str)
          str =~ /\A".*"\z/m || str =~ /\A'.*'\z/m ? true : false
        end

        # Single-quotes str if str has any special characters.
        def single_quote(str)
          needs_quote?(str) ? "'#{str.gsub(/'/, "'\\\\''")}'".gsub(/(\A|')''/) { $1 } : str
        end

        # Returns true if the word is a
        # {name}[http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap03.html#tag_03_230].
        #
        #   In the shell command language, a word consisting solely of underscores,
        #   digits, and alphabetics from the portable character set. The first
        #   character of a name is not a digit.
        #
        def name?(word)
          word =~ /\A[a-zA-Z_]\w*\z/ ? true : false
        end

        # Section 2.4 Reserved Words
        RESERVED_WORDS = %w[ ! { } case do done elif else esac fi for if in then until while ] + %w( [[ ]] function select )

        # Returns true if the word is a {reserved
        # word}[http://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html#tag_02_04].
        def reserved_word?(word)
          RESERVED_WORDS.include?(word) || (word[-1] == ?: && name?(word.chomp(':')))
        end
      end
    end
  end
end