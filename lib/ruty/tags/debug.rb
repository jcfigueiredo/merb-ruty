# = Ruty Debug Tag
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

require 'stringio'
require 'pp'

class Ruty::Tags::Debug < Ruty::Tag

  def initialize parser, argstring
    parser.fail('debug tag takes no arguments') if not argstring.empty?
  end

  def render_node context, stream
    buffer = StringIO.new
    PP.pp(context, buffer)
    buffer.rewind
    stream << buffer.read.strip
    buffer.close
  end

  Ruty::Tags.register(self, :debug)

end
