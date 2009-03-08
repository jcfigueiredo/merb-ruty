# = MerbRuty Filesystem Loader
class MerbRuty::Loaders::Filesystem < MerbRuty::Loader

  # the filesystem loader takes the following arguments:
  #
  #   :dirname (required)
  #     the path to the folder that includes the templates
  #
  #   :suffix (options)
  #     the suffix for all templates. For example '.tmpl'.
  #     Defaults to an empty string.
  def initialize options=nil
    super(options)
    unless @options.include?(:dirname)
      raise ArgumentError, 'dirname required as argument for filesystem loader'
    end
    @dir = @options[:dirname]
    @suffix = @options[:suffix] || ''
  end

 def load_local name, parent=nil, path=nil
    path = path || path_for?(name, parent)
    f = File.new(path, 'r')
    begin
      parser = MerbRuty::Parser.new(f.read, self, name)
    ensure
      f.close
    end
    parser.parse
  end

  def path_for? name, parent=nil
    # escape name, don't allow access to path parts with a
    # leading dot
    parts = name.split(File::SEPARATOR).select { |p| p and p[0] != ?. }
    path = File.join(@dir, (parent) ?
      path = File.join(File.dirname(parent), parts.join(File::SEPARATOR)) :
      path = parts.join(File::SEPARATOR)
    )
    raise MerbRuty::TemplateNotFound, name if not File.exist?(path)
    path
  end

end

#
## like the normal filesystem loader but uses memcaching
#class MerbRuty::Loaders::MemcachingFilesystem < MerbRuty::Loaders::Filesystem
#
#  # the memcaching filesystem loader takes the
#  # same arguments as the normal filesystem loader
#  # and additionally a key called :amount that indicates
#  # the maximum amount of cached templates. The amount
#  # defaults to 20.
#  def initialze options=nil
#    super(options)
#    @amount = @options[:amount] || 20
#    @cache = {}
#  end
#
#  def load_cached name, parent=nil
#    path = path_for?(name, parent)
#    return @cache[path] if @cache.include?(path)
#    nodelist = super(name, parent, path)
#    @cache.clear if @cache.size >= @amount
#    @cache[path] = nodelist
#  end
#
#end
