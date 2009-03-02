# = Ruty Context Class
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.


module Ruty

  # represents the internal namespace used by ruty
  # It basically works like a hash just that it has
  # multiple layers which can be pushed and popped.
  # That feature is used by the template engine in
  # loops, blocks and other block elements which set
  # variables.
  class Context
    include Enumerable

    # create a new context instance. initial can be
    # a hash which represents the initial root stack
    # which cannot be popped.
    def initialize initial=nil
      @stack = [initial || {}]
    end

    # push a new empty or given hash to the stack.
    def push hash=nil
      @stack << (hash or {})
    end

    # pop the outermost hash from the stack and return
    # it. The root hash is never popped, in that case
    # the method returns nil.
    def pop
      @stack.pop if @stack.size > 1
    end

    # manipulate the outermost hash.
    def []= name, value
      @stack[-1][name] = value
    end

    # start a recursive lookup for name.
    def [] name
      @stack.each do |hash|
        val = hash[name]
        return val if not val.nil?
      end
      nil
    end

    # checks if the key exists in one of the hashes.
    def has_key? key
      not send(:[], key).nil?
    end

    # call a block for each item in the context. if an item
    # exists in two layers, only the item from the higher
    # layer is yielded.
    def each &block
      found = {}
      @stack.reverse_each do |hash|
        hash.each do |key, value|
          next if found.include?(key)
          found[key] = hash
          block.call(key, value)
        end
      end
    end

    # overrides pretty print so that the output for the debug
    # tag looks nicer
    def pretty_print q
      t = {}
      each do |key, value|
        t[key] = value
      end
      q.pp_hash(t)
    end

    # method that resolves dotted names. Internal it first
    # tries to access hash keys, later array indices and if
    # this also does not work it looks for a ruty_safe?
    # function on the object, calls it with the current part
    # of the dotted name, and if it returns true it calls it
    # without arguments and uses the output as new object for
    # the next part.
    #
    #   {{ foo.bar.blah.42 }}
    #
    # could for example resolve this:
    #
    #   {{ foo['bar']['blah'][42] }}
    # 
    # call this method only with symbols, numbers and strings
    # are meant to be catched somewhere first.
    def resolve path
      # start a recursive lookup#
      current = self
      path.to_s.split(/\./).each do |part|
        part_sym = part.to_sym
        # try hash like objects (with has_key? and [])
        if current.respond_to?(:has_key?) and tmp = current[part_sym]
          current = tmp
        # try hash like objects with integers and array. If this
        # fails we don't try any longer because method names which
        # start with numbers are illegal.
        elsif part =~ /^-?\d+$/
          if current.respond_to?(:fetch) or current.respond_to?(:has_key?) \
             and tmp = current[part.to_i]
            current = tmp
          else
            return nil
          end
        # try method calls on objects with ruty_safe? methods
        elsif current.respond_to?(:ruty_safe?) and
              current.ruty_safe?(part_sym)
          current = current.send(part_sym)
        # fail with nil in all other cases.
        else
          return nil
        end
      end
      
      current
    end

    # apply filters on a value
    def apply_filters value, filters
      filters.each do |filter|
        name, args = filter[0], filter[1..-1]
        filter = Filters[name]
        raise TemplateRuntimeError, "filter '#{name}' missing" if filter.nil?
        args.map! do |arg|
          if arg.kind_of?(Symbol)
            resolve(arg)
          else
            arg
          end
        end
        value = filter.call(self, value, *args)
      end
      value
    end
  end
end
