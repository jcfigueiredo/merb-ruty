# = Ruty Filter Tag
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

class Ruty::Tags::Filter < Ruty::Tag

  def initialize parser, argstring
    @filters = parser.parse_arguments('|' + argstring)
    parser.fail('filter tag requires at least on filter') if @filters.empty?
    @nodelist = parser.parse_until { |n, a| n == :endfilter }
  end

  def render_node context, stream
    substream = Ruty::Datastructure::OutputStream.new
    @nodelist.render_node(context, substream)
    value = context.apply_filters(substream.to_s, @filters).to_s
    stream << value if not value.empty?
    nil
  end

  Ruty::Tags.register(self, :filter)

end
