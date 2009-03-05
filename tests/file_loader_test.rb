$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'merb-ruty'
require 'merb-ruty/loaders/filesystem'

class FileLoaderTest < Test::Unit::TestCase
  # Basic Template
  LAYOUT_TEMPLATE = 'layout.html'


  def setup
    @template_dir = Dir.getwd + '/tests/templates'
    @template_sufix = '.html'
  end

  def test_loader_setup

    loader = MerbRuty::Loaders::Filesystem.new(:dirname => @template_dir,:suffix => @template_sufix)
    assert_not_nil loader, 'The laoder should not be nil'

    assert loader.options.include? :dirname
    assert loader.options.include? :suffix
    assert_equal @template_dir, loader.options[:dirname], 'The dir name is not the expected'
    assert_equal @template_sufix, loader.options[:suffix], 'The sufix is not the expected'

  end

  def test_default_suffix_is_nil

    loader = MerbRuty::Loaders::Filesystem.new(:dirname => @template_dir)
    assert_nil loader.options[:suffix] , 'The sufix is empty'

  end

  def test_no_options_raises
    assert_raise(ArgumentError) { MerbRuty::Loaders::Filesystem.new('') }
  end

  def test_no_dirname_raises
    assert_raise(ArgumentError) { MerbRuty::Loaders::Filesystem.new(:suffix => @template_sufix) }
  end

  def test_template_path_resolution
    loader = MerbRuty::Loaders::Filesystem.new(:dirname => @template_dir, :suffix => @template_sufix)
    expected = '%s/tests/templates/layout.html' % Dir.getwd
    actual = loader.path_for? LAYOUT_TEMPLATE
    
    assert_equal expected, actual, 'Template path different from expected '
  end

  def test_template_path_resolution_with_parent
    loader = MerbRuty::Loaders::Filesystem.new(:dirname => Dir.getwd, :suffix => @template_sufix)
    expected  = '%s/tests/templates/layout.html' % Dir.getwd
    actual = loader.path_for? LAYOUT_TEMPLATE, '/tests/templates/layout'

    assert_equal expected, actual, 'Template path different from expected '
  end


  #  def test_layout_rendering
  #    loader = MerbRuty::Loaders::Filesystem.new(:dirname => templates_dir,:suffix => '.html')
  #    t = loader.get_template(LAYOUT_TEMPLATE)
  #    assert(rendered.include?(expected), 'Title not found')
  #  end
end
