# = Ruty Builtin Tags
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

require 'uri'

module Ruty

  # default class for all filter collections
  class FilterCollection

    # iterate over all filters, used by Filters to
    # register them.
    def self.each_filter &block
      instance = self.new
      instance_methods(false).each do |method_name|
        name = method_name.to_sym
        filter = instance.method(name).to_proc
        block.call(name, filter)
      end
    end
  end

  # builtin filter collection
  class StandardFilters < FilterCollection

    # convert a string to lowercase
    def lower context, value
      value.to_s.downcase
    end

    # convert a string to uppercase
    def upper context, value
      value.to_s.upcase
    end

    # capitalize a string
    def capitalize context, value
      value.to_s.capitalize
    end

    # truncate a string down to n characters
    def truncate context, value, n=80, ellipsis='...'
      if value
        if (value = value.to_s).length > n
          value[0...n] + ellipsis
        else
          value
        end
      else
        ''
      end
    end

    # join an array with a string between the array elements
    def join context, value, char=''
      if value.respond_to?(:join)
        value.join(char)
      else
        value
      end
    end

    # replace a substring with another
    # if the replacement string isn't given it replaces it with
    # an empty value.
    def replace context, value, search, repl=''
      value.to_s.gsub(search.to_s, repl.to_s)
    end

    # return a sorted version of an array or object that
    # supports sorting. If it does not this function returns
    # the value unchanged.
    def sort context, value
      if value.respond_to?(:sort)
        value.sort
      else
        value
      end
    end

    # reverse an item that supports reversing. else return
    # the item unchanged
    def reverse context, value
      if value.respond_to?(:reverse)
        value.reverse
      else
        value
      end
    end

    # get the first item of an array
    def first context, value
      if value.respond_to?(:first)
        value.first
      elsif value.respond_to?(:[])
        value[0] || value
      else
        value
      end
    end

    # get the last item of an array
    def last context, value
      if value.respond_to?(:last)
        value.last
      elsif value.respond_to?(:[])
        value[-1] || value
      else
        value
      end
    end

    # xml escape a string
    def escape context, value, attribute=false
      value = value.to_s.gsub(/&/, '&amp;')\
                        .gsub(/>/, '&gt;')\
                        .gsub(/</, '&lt;')
      value.gsub!(/"/, '&quot;') if attribute
      value
    end

    # urlencode an string
    def urlencode context, value
      URI.escape(value.to_s)
    end

    # return the length of an object
    def length context, value
      if value.respond_to?(:size)
        value.size
      elsif value.respond_to?(:length)
        value.length
      elsif value.respond_to?(:count)
        value.count
      else
        0
      end
    end

  end

  # module used to lookup filters
  module Filters
    @collections = {}
    @filters = {}

    class << self
      # return filter `name`
      def [] name
        @filters[name]
      end

      # register a new filter collection
      def register_collection collection
        return if @collections.include? collection
        collection.each_filter {|name, filter|
          @filters[name] = filter
        }
        @collections[collection] = true
        nil
      end

      # add just one filter using a code block:
      # Ruty::Filters::add('swapcase') { |context, value|
      #   value.to_s.swap_case
      # }
      def add name, &block
        raise AttributeError, 'block required' if !block
        @filters[name] = block
      end

      # return an array of symbols containing the names
      # of all registered filters.
      def all
        return @filters.keys
      end
    end
  end

  # bootstrap filters module and register builtin filters
  Filters.register_collection(StandardFilters)

end
