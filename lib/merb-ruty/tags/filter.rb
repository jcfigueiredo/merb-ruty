# = MerbRuty Filter Tag

class MerbRuty::Tags::Filter < MerbRuty::Tag

  def initialize parser, argstring
    @filters = parser.parse_arguments('|' + argstring)
    parser.fail('filter tag requires at least on filter') if @filters.empty?
    @nodelist = parser.parse_until { |n, a| n == :endfilter }
  end

  def render_node context, stream
    substream = MerbRuty::Datastructure::OutputStream.new
    @nodelist.render_node(context, substream)
    value = context.apply_filters(substream.to_s, @filters).to_s
    stream << value if not value.empty?
    nil
  end

  MerbRuty::Tags.register(self, :filter)

end
