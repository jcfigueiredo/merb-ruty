# = Ruty Loaders
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

module Ruty

  # base class for all loaders
  class Loader
    attr_reader :options

    def initialize options=nil
      if not options.nil? and not options.is_a?(Hash)
        raise ArgumentError, 'loader options must be a hash or omitted'
      end
      @options = options or {}
    end

    # load a template, probably from cache
    # Per default this calls the load_local method with the
    # same paramters
    def load_cached name, parent=nil
      load_local(name, parent)
    end

    # load a template by always reparsing it. That for example
    # is used by the inheritance and inclusion system because
    # the tags modify the nodelist returned by a loader.
    # If parent is given it must be used to resolve relative
    # paths
    def load_local name, parent=nil
      raise NotImplementedError
    end

    # method for loading templates in an application. Returns a
    # template instance with the loaded name.
    def get_template name
      Template.new(load_cached(name))
    end

  end

  module Loaders
  end

  # load known builtin loaders
  require 'ruty/loaders/filesystem'

end
