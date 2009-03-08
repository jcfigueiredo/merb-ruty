# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'merb-ruty'
require 'fileutils'
require 'merb-ruty/loaders/filesystem'

class TemplateInheritanceTest < Test::Unit::TestCase

  def setup
    @curr_dir = Dir.getwd.sub("/tests", "")
  end

  def test_simple_inheritance
    title = "Your title has been overwritten"
    expected = "<title>%s</title>" % title
    
    templates_dir = @curr_dir  + '/tests/templates'

    loader = MerbRuty::Loaders::Filesystem.new(:dirname => templates_dir,:suffix => '.html')
    t = loader.get_template('index.html')

    rendered =  t.render(:real_title => title)

    assert(rendered.include?(expected), 'Title not found')
  end
end
