# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'merb-ruty'

class SimpleRenderingTest < Test::Unit::TestCase
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

end
