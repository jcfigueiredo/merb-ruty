# = MerbRuty Template Inheritance

# special tag that marks a part of a template for inheritance.
# If a template extends from a template with a block tag with
# the same name it will replace the block in the inherited
# template with the block with the same name in the current
# template.
class MerbRuty::Tags::Block < MerbRuty::Tag

  def initialize parser, argstring
    if not argstring =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/
      parser.fail('Invalid syntax for block tag')
    end
    @name = argstring.to_sym
    @stack = [parser.parse_until { |name, a| name == :endblock }]

    blocks = (parser.storage[:blocks] ||= {})
    parser.fail("block '#{@name}' defined twice") if blocks.include?(@name)
    blocks[@name] = self
  end

  def add_layer nodelist
    @stack << nodelist
  end

  def render_node context, stream, index=-1
    context.push
    context[:block] = MerbRuty::Datastructure::Deferred.new(
      :super =>     Proc.new {
        render_node(context, stream, index - 1) if index.abs <= @stack.size
      },
      :depth =>     Proc.new { index.abs },
      :name =>      Proc.new { @name }
    )
    @stack[index].render_node(context, stream)
    context.pop
    nil
  end

  MerbRuty::Tags.register(self, :block)

end

# tag used to load a template from another file. must be the first
# tag of a document!
class MerbRuty::Tags::Extends < MerbRuty::Tag

  def initialize parser, argstring
    if not parser.first
      parser.fail('extends tag must be at the beginning of a template')
    elsif not argstring =~ /^(["'])(.*?)\1$/
      parser.fail('extends takes exactly one argument which must be ' +
                  'an hardcoded string')
    end

    # parse the template to the end and load parent nodelist
    parser.parse_all
    @nodelist = parser.load_local(argstring[1...-1])
    blocks = @nodelist.parser.storage[:blocks] || {}

    # iterate over all blocks found while parsing and add them
    # to the parent nodelist which will be the new nodelist
    (parser.storage[:blocks] || []).each do |name, tag|
      blocks[name].add_layer(tag) if blocks.include?(name)
    end
  end

  def render_node context, stream
    @nodelist.render_node(context, stream)
  end

  MerbRuty::Tags.register(self, :extends)

end
