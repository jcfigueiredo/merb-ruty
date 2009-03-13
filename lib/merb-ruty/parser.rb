# = MerbRuty Parser

require 'strscan'


module MerbRuty

  # the parser class. parses a given template into a nodelist
  class Parser

    TAG_REGEX = /
      (.*?)(?:
        #{Regexp.escape(Constants::BLOCK_START)}    (.*?)
        #{Regexp.escape(Constants::BLOCK_END)}          |
        #{Regexp.escape(Constants::VAR_START)}      (.*?)
        #{Regexp.escape(Constants::VAR_END)}            |
        #{Regexp.escape(Constants::COMMENT_START)}  (.*?)
        #{Regexp.escape(Constants::COMMENT_END)}
      )
    /xim

    STRING_ESCAPE_REGEX = /\\([\\nt'"])/m

    # create a new parser for a given sourcecode and an optional
    # template loader. If a template loader is given the template
    # inheritance and include system will work. Otherwise those
    # tags create an error.
    # If name is given it will be used by the loaders to resolve
    # relative paths on inclutions/inheritance
    def initialize source, loader=nil, name=nil
      @source = source
      @loader = loader
      @name = name
    end

    # parse the template and return a nodelist representing
    # the parsed template.
    def parse
      controller = ParserController::new(tokenize, @loader, @name)
      controller.parse_all
    end

    # tokenize the sourcecode and return an array of tokens
    def tokenize
      result = Datastructure::TokenStream.new
      @source.scan(TAG_REGEX).each do |match|
        result << [:text, match[0]] if match[0] and not match[0].empty?
        if data = match[1]
          result << [:block, data.strip]
        elsif data = match[2]
          result << [:var, data.strip]
        elsif data = match[3]
          result << [:comment, data.strip]
        end
      end
      rest = @source[$~.end(0)..-1]
      result << [:text, rest] if not rest.empty?
      result.close
    end

    # helper function for parsing arguments
    # the return value will be a list of lists. names are returned
    # as symbols, strings as strings, numbers as floats or integers,
    # filters are returned as arrays:
    #
    #   for item in seq
    #
    # results in:
    #
    #   [:for, :item, :in, :seq]
    #
    # This:
    #
    #   user.username|lower|replace '\'', '"'
    #
    # results in:
    #
    #   [:"user.username", [:lower], [:replace, "'", "\""]]
    def self.parse_arguments arguments
      lexer = Parser::ArgumentLexer.new(arguments)
      result = cur_buffer = []
      filter_buffer = []

      lexer.lex do |token, value|
        if token == :filter_start
          cur_buffer = filter_buffer.clear
        elsif token == :filter_end
          result << filter_buffer.dup if not filter_buffer.empty?
          cur_buffer = result
        elsif token == :first_name
          cur_buffer << value.to_sym
        elsif token == :number
          cur_buffer << (value.include?('.') ? value.to_f : value.to_i)
        elsif token == :string
          cur_buffer << value[1...-1].gsub(STRING_ESCAPE_REGEX) {
            $1.tr!(%q{\\\\nt"'}, %q{\\\\\n\t"'})
          }
        end
      end

      result
    end

    # class for parsing arguments. used by the parse_arguments
    # function. It's usualy a better idea to not use this class
    # yourself because it's pretty low level.
    class ArgumentLexer

      # lexer constants
      WHITESPACE_RE = /\s+/m
      NAME_RE = /[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z0-9_][a-zA-Z0-9_]*)*/
      PIPE_RE = /\|/
      FILTER_END_RE = /;/
      SEPARATOR_RE = /,/
      STRING_RE = /
        (?:
          "([^"\\]*(?:\\.[^"\\]*)*)"
        |
          '([^'\\]*(?:\\.[^'\\]*)*)'
        )
      /xm
      NUMBER_RE = /\d+(\.\d*)?/

      # create a new ArgumentLexer for the given string
      def initialize string
        @string = string
      end

      # lex the string. For each return token this function calls
      # the given block with the token type and value.
      def lex &block
        s = StringScanner.new(@string)
        state = :initial

        while not s.eos?
          # supress whitespace. no matter in which state we are.
          next if s.scan(WHITESPACE_RE)

          # normal data, no filters.
          if state == :initial
            if match = s.scan(NAME_RE)
              block.call(:first_name, match)
            elsif s.scan(PIPE_RE)
              state = :filter
              block.call(:filter_start, nil)
            elsif s.scan(SEPARATOR_RE)
              block.call(:separator, nil)
            elsif match = s.scan(STRING_RE)
              block.call(:string, match)
            elsif match = s.scan(NUMBER_RE)
              block.call(:number, match)
            else
              # nothing matched and we are not at the end of
              # the string, raise an error
              raise TemplateSyntaxError, 'unexpected character ' \
                                         "'#{s.getch}' in block tag"
            end
          
          # filter syntax
          elsif state == :filter
            # if a second pipe occours we start a new filter
            if s.scan(PIPE_RE)
              block.call(:filter_end, nil)
              block.call(:filter_start, nil)
            # filter ends with ; -- handle that
            elsif s.scan(FILTER_END_RE)
              block.call(:filter_end, nil)
              state = :initial
            elsif s.scan(SEPARATOR_RE)
              block.call(:separator, nil)
            # variables, strings and numbers
            elsif match = s.scan(NAME_RE)
              block.call(:first_name, match)
            elsif match = s.scan(STRING_RE)
              block.call(:string, match)
            elsif match = s.scan(NUMBER_RE)
              block.call(:number, match)
            else
              # nothing matched and we are not at the end of
              # the string, raise an error
              raise TemplateSyntaxError, 'unexpected character ' \
                                         "'#{s.getch}' in filter def"
            end
          end
        end
        block.call(:filter_end, nil) if state == :filter
      end
    end
  end

  # parser controller. does the actual parsing, used by
  # the tags to control it.
  class ParserController

    attr_reader :tokenstream, :storage, :first
    
    def initialize stream, loader, name
      @loader = loader
      @name = name
      @tokenstream = stream
      @first = true
      @storage = {}
    end

    # fail with an template syntax error exception.
    def fail msg
      raise TemplateSyntaxError, msg
    end

    # alias for the method with the same name on the
    # parser class
    def parse_arguments arguments
      Parser::parse_arguments(arguments)
    end

    # use the loader to load a subtemplate
    def load_local name
      raise TemplateRuntimeError, 'no loader defined' if not @loader
      @loader.load_local(name, @name)
    end

    # parse everything until the block returns true
    def parse_until &block
      result = Datastructure::NodeStream.new(self)
      while not @tokenstream.eos?
        token, value = @tokenstream.next

        # text tokens are returned just if the arn't empty
        if token == :text
          @first = false if @first and not value.strip.empty?
          result << Datastructure::TextNode.new(value) \
                    if not value.empty?

        # variables leave the parser just if they have just
        # one name and some optional filters on it.
        elsif token == :var
          @first = false
          names = []
          filters = []
          Parser::parse_arguments(value).each do |arg|
            if arg.is_a?(Array)
              filters << arg
            else
              names << arg
            end
          end

          fail('Invalid syntax for variable node') if names.size != 1
          result << Datastructure::VariableNode.new(names[0], filters)

        # blocks are a bit more complicated. first they can act as
        # needle tokens for other blocks, on the other hand blocks
        # can have their own subprogram
        elsif token == :block
          p = value.split(/\s+/, 2)
          name = p[0].to_sym
          args = p[1] || ''
          if block.call(name, args)
            @first = false
            return result.to_nodelist
          end

          tag = Tags[name]
          fail("Unknown tag #{name.inspect}") if tag.nil?
          result << tag.new(self, args)
          @first = false
        end
      end
      result.to_nodelist
    end

    # parse everything and return the nodelist for it
    def parse_all
      parse_until { false }
    end
  end
end
