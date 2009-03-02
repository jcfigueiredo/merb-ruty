# = Ruty Builtin Tags
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

module Ruty

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
  require 'ruty/tags/forloop'
  require 'ruty/tags/conditional'
  require 'ruty/tags/looptools'
  require 'ruty/tags/inheritance'
  require 'ruty/tags/inclusion'
  require 'ruty/tags/debug'
  require 'ruty/tags/filter'
  require 'ruty/tags/capture'

end
