# = Ruty Conditional Tags
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

class Ruty::Tags::If < Ruty::Tag

  def initialize parser, argstring
    # parse everything until the next else or endif tag
    # and save in a variable if it was a else tag for
    # postprocessing.
    was_else = false
    @body = parser.parse_until do |name, a|
      if [:endif, :else].include? name
        was_else = name == :else
        true
      end
    end

    args = parser.parse_arguments(argstring)
    @else_body = parser.parse_until { |name, a| name == :endif } if was_else

    if not [1, 2].include?(args.length) or \
       (args.length == 2 and args[0] != :not)
      parser.fail('invalid syntax for if tag')
    end

    @negated = args.length == 2
    @item = @negated ? args[1] : args[0]
  end

  def render_node context, stream
    item = context.resolve(@item)
    if item == false
      val = false
    elsif item.respond_to?(:nonzero?)
      val = item.nonzero?
    elsif item.respond_to?(:empty?)
      val = !item.empty?
    elsif item.respond_to?(:size)
      val = item.size > 0
    elsif item.respond_to?(:length)
      val = item.length > 0
    else
      val = !item.nil?
    end
    if @negated ? !val : val
      @body.render_node(context, stream)
    elsif @else_body
      @else_body.render_node(context, stream)
    end
  end

  Ruty::Tags.register(self, :if)

end
