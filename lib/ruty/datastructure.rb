# = Ruty Data Structure
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

require 'stringio'

module Ruty::Datastructure

  # baseclass for all nodes
  class Node
    
    # render the block and call the block for each return value
    def render_node context, stream
    end
  end

  # node list class. can store multiple nodes
  class NodeList < Node
    include Enumerable
    attr_reader :parser
    
    def initialize initial=nil, parser=nil
      @nodes = initial || []
      @parser = parser
    end

    def << node
      @nodes << node
    end

    def each &block
      @nodes.each(&block)
    end

    def render_node context, stream
      @nodes.each do |node|
        node.render_node(context, stream)
      end
      nil
    end
  end

  # a node that stores text data
  class TextNode < Node
    
    def initialize text
      @text = text
    end

    def render_node context, stream
      stream << @text
      nil
    end
  end

  # a node that stores a variable plus filters
  class VariableNode < Node
    
    def initialize name, filters
      @name = name
      @filters = filters
    end

    def render_node context, stream
      value = context.apply_filters(context.resolve(@name), @filters).to_s
      stream << value if not value.empty?
      nil
    end
  end

  # stream class. Some kind of write only array which just
  # accepts nodes and can be converted into a nodelist afterwards.
  class NodeStream
    def initialize parser
      @parser = parser
      @stream = []
      @nodelist = nil
    end

    # add a new node to the stream
    def << node
      raise RuntimeError, 'cannot write to closed stream' if @nodelist
      @stream << node
    end

    # convert the streamed data into a nodelist. This
    # automatically closes the stream, you can't write
    # to it later.
    def to_nodelist
      @nodelist = NodeList.new(@stream, @parser) if not @nodelist
      @nodelist
    end
  end

  # stream for the tokenize function
  class TokenStream

    def initialize
      @stream = []
      @closed = false
      @pushed = []
    end

    def next
      if not @pushed.empty?
        @pushed.pop
      else
        @stream.pop
      end
    end

    def eos?
      @stream.empty?
    end

    # push a token to a closed or nonclosed stream.
    # pushed tokens are always processed first in
    # reverse order
    def push token
      @pushed << token
    end

    # add one token to a non closed stream
    # once the stream is closed you can still add tokens
    # to the stream but by pushing back which you can do
    # by calling push.
    def << token
      raise RuntimeError, 'cannot write to closed stream' if @closed
      @stream << token
    end

    # close the stream and return self
    def close
      raise RuntimeError, 'cannot close closed token stream' if @closed
      @closed = true
      @stream.reverse!
      self
    end
  end

  # special class that is used by some ruty tags to
  # provide data for the context that requires calculation
  # or rendering and is optional (for example block.super)
  class Deferred
    
    def initialize callables=nil
      @callables = callables || {}
    end

    def add_deferred name, &block
      @callables[name] = block
    end

    def ruty_safe? name
      @callables.include?(name)
    end

    def method_missing name
      @callables[name].call if @callables.include?(name)
    end

    # override the pretty print callback function so that we
    # get values instead of just a lot of proc inspect outputs.
    def pretty_print q
      unknown = (Class.new{
        define_method(:inspect) { '?' }
      }).new
      t = {}
      @callables.each do |name, callable|
        t[name] = callable.call rescue unknown
      end
      q.pp_hash(t)
    end
  end

end
