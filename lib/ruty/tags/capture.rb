# = Ruty Capture Tag
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

class Ruty::Tags::Capture < Ruty::Tag

  def initialize parser, argstring
    if not argstring =~ /^as\s+([a-zA-Z_][a-zA-Z0-9_]*)$/
      parser.fail('syntax for capture tag: {% capture as <variable> %}')
    end

    @name = $1.to_sym
    @nodelist = parser.parse_until { |n, a| n == :endcapture }
  end

  def render_node context, stream
    substream = ''
    @nodelist.render(context, substream)
    context[@name] = substream
  end

  Ruty::Tags.register(self, :include)

end
