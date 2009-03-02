# = Ruty Include Tags
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

# simple include tag. just includes another template at
# the current position. (for header/footer inclusion for
# example, although it's better to use extends in combination
# with some blocks)
class Ruty::Tags::Include < Ruty::Tag

  def initialize parser, argstring
    if not argstring =~ /^("')(.*?)\1$/
      parser.fail('include takes exactly one argument which must be ' +
                  'an hardcoded string')
    end

    # load given template using the load_local function of the parser
    @nodelist = parser.load_local(argstring[1...-1])
  end

  def render_node context, stream
    @nodelist.render_node(context, stream)
  end

  Ruty::Tags.register(self, :include)

end
