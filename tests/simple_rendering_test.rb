$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'merb-ruty'
require 'fileutils'
require 'merb-ruty/loaders/filesystem'


class SimpleRenderingTest < Test::Unit::TestCase

  def setup
    @curr_dir = Dir.getwd.sub("/tests", "")
  end

  def test_render_template_works_with_valid_values
    expected = "Hello Claudio Figueiredo!"
    t = MerbRuty::Template.new('Hello {{ username }}!')
    rendered =  t.render(:username => 'Claudio Figueiredo')

    assert_equal expected, rendered, 'Message is different from expected'
  end

  def test_render_template_fails_with_invalid_values
    expected = "Hello Claudio Figueiredo!"
    t = MerbRuty::Template.new('Hello {{ username }}!')
    rendered =  t.render(:username => 'Claudio Souza')

    assert_not_equal expected, rendered, 'Message is different from expected'
  end

  def test_debug_message
    t = MerbRuty::Template.new('{% debug %}!')
    rendered =  t.render(:alpha => 'beta')

    assert_not_nil rendered, 'Result should no be nil'
  end

  def test_layout_rendering
    title = "You've been rendered"
    expected = "<title>%s</title>" % title

    templates_dir = @curr_dir  + '/tests/templates'

    loader = MerbRuty::Loaders::Filesystem.new(:dirname => templates_dir,:suffix => '.html')
    t = loader.get_template('layout.html')

    rendered =  t.render(:title => title)
    
    assert(rendered.include?(expected), 'Title not found')

  end

end
