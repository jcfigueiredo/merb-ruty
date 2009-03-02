# = Ruty Loop Tool Tags
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

# A tag that cycles through a list of values each iteration
# Useful for example if you want alternating rows:
#
#   {% for row in rows %}
#     <tr class="{% cycle 'row1', 'row2' %}">
#       <td>..</td>
#     </tr>
#   {% endfor %}
class Ruty::Tags::Cycle < Ruty::Tag

  def initialize parser, argstring
    args = parser.parse_arguments(argstring)
    parser.fail('At least one item is required for cycle') if args.empty?
    @items = args
  end

  def render_node context, stream
    item = @items[context[self] = ((context[self] || -1) + 1) % @items.length]
    item = context.resolve(item) if item.is_a?(Symbol)
    stream << item.to_s
    nil
  end

  Ruty::Tags.register(self, :cycle)

end


# just render everything between the tag and the closing
# endifchanged tag if the given variable hasn't changed
# from the last iteration. If no variable is given the
# block will check it's own rendering against the
# rendering of the last iteration.
#
# {% for day in days %}
#   <div class="day">
#     <h2>{{ day.name|escape }}</h2>
#     {% for entry in day.entries %}
#       {% ifchanged entry.pub_date.hour %}
#         <h3>{{ entry.pub_date }}</h3>
#       {% endifchanged %}
#       ...
#     {% endfor %}
#   </div>
# {% endfor %}
class Ruty::Tags::IfChanged < Ruty::Tag

  def initialize parser, argstring
    args = parser.parse_arguments(argstring)
    if not [0, 1].include?(args.length)
      parser.fail('ifchanged-tag takes at most one argument')
    end
    @arg = args[0]
    @body = parser.parse_until { |name, a| name == :endifchanged }
  end

  def render_node context, stream
    if not @arg
      substream = Datastructure::OutputStream.new
      @body.render_node(context, substream)
      this_iteration = substream.to_s
      if this_iteration != context[self]
        block << this_iteration
        context[self] = this_iteration
      end
    else
      item = (@arg.is_a?(Symbol)) ? context.resolve(@arg) : @arg
      if item != context[self]
        @body.render_node(context, stream)
        context[self] = item
      end
    end
    nil
  end

  Ruty::Tags.register(self, :ifchanged)
end
