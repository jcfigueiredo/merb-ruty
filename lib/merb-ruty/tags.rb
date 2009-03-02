# = MerbRuty Builtin Tags

module MerbRuty

  # base class for all ruty tags
  class Tag < Datastructure::Node
  end

  # builtin tags
  module Tags
    @tags = {}

    class << self
      # function for quickly looking up tags by name
      def [] name
        @tags[name]
      end

      # array of all known tags by name
      def all
        @tags.keys
      end

      # function used for registering a new tag.
      def register tag, name
        @tags[name] = tag
      end

      # function used to unregister a function
      def unregister name
        @tags.delete(name)
      end
    end
  end

  # load known builtin tags
  require 'merb-ruty/tags/forloop'
  require 'merb-ruty/tags/conditional'
  require 'merb-ruty/tags/looptools'
  require 'merb-ruty/tags/inheritance'
  require 'merb-ruty/tags/inclusion'
  require 'merb-ruty/tags/debug'
  require 'merb-ruty/tags/filter'
  require 'merb-ruty/tags/capture'

end
