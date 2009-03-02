# = MerbRuty Debug Tag

require 'stringio'
require 'pp'

class MerbRuty::Tags::Debug < MerbRuty::Tag

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

  MerbRuty::Tags.register(self, :debug)

end
