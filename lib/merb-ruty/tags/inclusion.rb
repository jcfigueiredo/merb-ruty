# = MerbRuty Include Tags

# simple include tag. just includes another template at
# the current position. (for header/footer inclusion for
# example, although it's better to use extends in combination
# with some blocks)
class MerbRuty::Tags::Include < MerbRuty::Tag

  def initialize parser, argstring
    if not argstring =~ /^["'].*["']$/
      parser.fail('include takes exactly one argument which must be ' +
                  'an hardcoded string')
    end

    # load given template using the load_local function of the parser
    @nodelist = parser.load_local(argstring[1...-1])
  end

  def render_node context, stream
    @nodelist.render_node(context, stream)
  end

  MerbRuty::Tags.register(self, :include)

end
