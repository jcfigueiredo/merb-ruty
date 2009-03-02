# = Ruty For Loop Tag
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

class Ruty::Tags::ForLoop < Ruty::Tag

  def initialize parser, argstring
    # parse everything until the next else or endfor tag
    # and save in a variable if it was a else tag or an
    # endfor tag so that we can parse the second part if
    # required later.
    was_else = false
    @body = parser.parse_until do |name, a|
      if [:endfor, :else].include? name
        was_else = name == :else
        true
      end
    end
    
    args = parser.parse_arguments(argstring)
    @else_body = parser.parse_until { |name, a| name == :endfor } if was_else
    if args.length != 3 or args[1] != :in
      parser.fail('invalid syntax for for-loop tag')
    end
    @item = args[0]
    @iterable = args[2]
  end

  def render_node context, stream
    iterable = context.resolve(@iterable)
    length = 0
    if iterable.respond_to?(:each)
      if iterable.respond_to?(:size)
        length = iterable.size
      elsif iterable.respond_to?(:length)
        length = iterable.length
      end
    end

    if length > 0
      index = 0
      parent = context[:loop]
      context.push

      iterable.each do |item|
        break if index == length
        context[@item] = item
        context[:loop] = {
          :parent =>          parent,
          :index =>           index + 1,
          :index0 =>          index,
          :revindex =>        length - index,
          :revindex0 =>       length - index - 1,
          :first =>           index == 0,
          :last =>            length - index == 1,
          :length =>          length,
          :even =>            index % 2 != 0,
          :odd =>             index % 2 == 0
        }
        @body.render_node(context, stream)
        index += 1
      end
      if index != 0
        context.pop
        return nil
      end
    end

    # if we reach this point there was no iteration. either because
    # we tried to iterate something without a size or it was an object
    # that isn't iterable, render the else_body if given
    @else_body.render_node(context, stream) if @else_body
    context.pop
    nil
  end

  Ruty::Tags.register(self, :for)

end
