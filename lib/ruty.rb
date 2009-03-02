# = Ruty -- Ruby Templating
# 
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.
#
#
# Ruty is a template engine heavily inspired by the Django and Jinja Template
# Engine. It supports template inheritance, template inclusion and most of the
# tags supported by Jinja/Django.
#
# Quickstart
# ==========
#
# The simplest way to load templates is by using the Ruty::Template class:
#
#   require 'ruty'
#   t = Ruty::Template.new('Hello {{ username }}!')
#   puts r.render(:username => 'John Doe')
#
# Outputs:
#   Hello John Doe!
#
# By just using the Ruty::Template class you can't use the powerful template
# inheritance system of ruty. To have that working you must load templates
# via a loader instance. Ruty ships two loaders, the Filesystem loader and
# MemcachedFilesystem loader:
#
#   require 'ruty'
#   loader = Ruty::Loaders::Filesystem.new(:dirname => './templates')
#   t = loader.get_template('index.html')
#   puts t.render(...)
#
# In this example the loader wants you to save your templates in the folder
# called './templates'. For a list of supported arguments have a look at
# the module documentation of the loaders.
#
# You can easily add loaders yourself. Documentation regarding that is
# comming... maybe... (hey. the ruby sourcecode isn't documented either)
#
# Variables
# =========
#
# Variables look like this: {{ variable }}. When the template engine
# encounters a variable, it evaluates that variable and replaces it with the
# result. You can use a dot to access keys, indexes or attributes of a
# variable.
#
# Behind the scenes ruty does the following:
#   - hash key lookup
#   - array index lookup
#   - method call*
#
# *ruty only calls methods without arguments and only if the object holding
# those methods returns true for the ruty_safe? method which is called with
# the requested method name. Here an example to add support for .downcase
# and .upcase calls on strings (which is not useful since there are filters
# which are covered in the next section):
#
#   class String
#     def ruty_safe? name
#       return [:downcase, :upcase].include?(name)
#     end
#   end
#
# Filters
# =======
#
# Variables support filters which modify a variable. Filters look like this:
#   
#   {{ variable|filter1|filter "with", "some", "arguments" }}.
#
# As you can see you can chain filters using the pipe (|) symbol. You can
# also add filters yourself:
#
#   require 'ruty'
#
#   class MyFilters < Ruty::FilterCollection
#     def my_filter context, value, *arguments
#       "#{value} called with #{arguments.inspect}"
#     end
#
#     Ruty::Filters.register_collection(self)
#   end
#
# Now the filter my_filter will be available in all templates. The first
# argument of a filter is always the context, an object holding the stacked
# namespace passed to the template. Usually you don't have to access it but
# sometimes it might be useful.
#
# The following filters exist by default
#
#   lower
#   -----
#     convert a value to lowercase
#
#   upper
#   -----
#     convert a value to uppercase
#
#   capitalize
#   ----------
#     capitalizes a string
#
#   truncate n=80, ellipsis='...'
#   -----------------------------
#     truncates a string to n characters. If the string was truncated
#     the ellipsis is appended.
#
#   join char=''
#   ------------
#     joins an array with a given string.
#
#   sort
#   ----
#     return a sorted version of the value if sorting is supported
#
#   reverse
#   -------
#     reverses an item if this is supported
#
#   first
#   -----
#     return the first item of a array
#
#   last
#   ----
#     return the last item of an array
#
#   escape attribute=false
#   ----------------------
#     xml-escape a string. If attribute is true it will also escape
#     " to &quot;
#
#   urlencode
#   ---------
#     urlencodes a string (" " will be converted to "%20" etc.)
#
#   length
#   ------
#     return the length of an item with a length, 0 else
#   
#
# Comments
# ========
#
# Comments look like this:
#
#   {# this is a comment #}
#
# Tags
# ====
#
# Tags look pretty much like variables but they use a percentage sign instead
# of a second brace:
#
#   {% tag some, arguments %}
#
# Some tags require beginning and ending tags:
#   
#   {% tag %}
#      ... tag contents ...
#   {% endtag %}
#
# Here a list of builtin tags:
#
#   For Loop
#   --------
#
#   The for loop is useful if you want to iterate over something that
#   supports iteration. For example arrays:
#
#     <ul>
#     {% for item in iterable %}
#       <li>{{ item|escape }}</li>
#     {% endfor %}
#     </ul>
#
#   Inside of a loop you have access to some loop variables:
#
#     loop.index      The current iteration of the loop (1-indexed)
#     loop.index0     The current iteration of the loop (0-indexed)
#     loop.revindex   The number of iterations from the end of
#                     the loop (1-indexed)
#     loop.revindex0  The number of iterations from the end of the
#                     loop (0-indexed)
#     loop.first      true if this is the first time through the loop
#     loop.last       true if this is the last time through the loop
#     loop.even       true if this is an even iteration
#     loop.odd        true if this is an odd iteration
#     loop.parent     For nested loops, this is the loop "above" the
#                     current one
#
#   For loops also have an optional else block that is just rendered
#   if the iteration was empty:
#
#     {% for user in users %}
#       ...
#     {% else %}
#       no users found
#     {% endfor %}
#
#   Important Note: Ruty requires objects to not only provide a valid
#   each method for iteration but also a size or length method that
#   returns the number of items. If size and length isn't provided
#   ruty fails silently and renders the else block if given. The same
#   happens if you try to iterate over a number or any other object
#   without an each method.
#
#   If Conditions
#   -------------
#
#   If Conditions are very low featured, they only support boolean
#   checks. But they do boolean checks a clever way, so not the ruby
#   way ^^. For example empty objects are considered false, zero, nil
#   and false too.
#
#   Syntax:
#
#     {% if item %}
#       ...
#     {% endif %}
#
#   Or:
#
#     {% if not item %}
#       ...
#     {% else %}
#       ...
#     {% endif %}
#
#   There is neither or/and or elsif by now. But that's something that is
#   on the todo list.
#
#   Cycle
#   -----
#
#   Cycle among the given objects each time this tag is encountered.
#   Within a loop, cycles among the given strings each time through the loop:
#
#     {% for item in iterable %}
#       <tr class="{% cycle 'row1', 'row2' %}">
#         ...
#       </tr>
#     {% endfor %}
#
#   Capture
#   -------
#
#   Captures the wrapped data and puts it into a variable:
#
#     {% capture as title %}{% block title %}...{% endblock %}{% endcapture %}
#
#   That allows using the data of a block multiple times. Note that the
#   variable is only available in the current and lower scopes. If you use
#   this block to capture something inside a for loop tag for example (or
#   inside of a block) it won't be available outside of the loop/block.
#
#   Ifchanged
#   ---------
#
#   Check if a value has changed from the last iteration of a loop. If
#   a variable is given as first argument it's used for testing, otherwise
#   the output of the tag:
#
#     {% for day in days %}
#       {% ifchanged %}<h3>{{ date.hour }}</h3>{% endifchanged %}
#       ...
#     {% endfor %}
#
#   Or:
#
#     {% for day in days %}
#       {% ifchanged date.hour %}
#         ...
#       {% endifchanged %}
#     {% endfor %}
#
#   Giving the tag a variable to check against will speed out the rendering
#   process.
#
#   Filter
#   ------
#
#   Applies some filters on the wrapped content:
#
#     {% filter upper|escape %}
#       <some content here & that includes < invalid
#       html we want to escape and > convert to uppercase
#     {% endfilter %}
#
#   Debug
#   -----
#
#   This tag outputs a pretty printed represenation of the context
#   passed to the template:
#
#     {% debug %}
#
#   If you want to use the output in a html document use this to get a
#   readable output:
#
#     <pre>{% filter escape %}{% debug %}{% endfilter %}</pre>
#
#   Include
#   -------
#   
#   If the template was loaded by a loader it can include other templates:
#
#     {% include 'name_of_other_template.html' %}
#
#   Template import paths are usually relative, some loaders might redefine
#   that behavior.
#
#   Block / Extends
#   ---------------
#
#   Now to the template inheritance system. Template inheritance allows you
#   to build a base "skeleton" template that contains all the common elements
#   of your site and defines blocks that child templates can override:
#
#     <html>
#       <head>
#       {% block head %}
#         <title>{% block title %}My Webpage{% endblock %}</title>
#       {% endblock %}
#       </head>
#       <body>
#         <div class="header">...</div>
#         <div class="body">{% block body %}{% endblock %}</div>
#       </body>
#     </html>
#
#   Saved as layout.html it can act as a layout template for the child template
#   (for example called userlist.html):
#
#     {% extends 'layout.html' %}
#     {% block title %}Userlist | {{ block.super }}{% endblock %}
#     {% block body %}
#       <ul>
#       {% for user in users %}
#         <li>{{ user|escape }}</li>
#       {% endfor %}
#       </ul>
#     {% endblock %}
#
#   As you can see block override each other, because of that block names
#   must be unique! You can render the output of an overridden block by
#   outputting block.super. The name of a block is available as block.name,
#   the depth of the current inheritance as block.depth.
#
#   Note that extends must be the first tag of a template. Otherwise the
#   whole process fails with an error message.
#
# Ruty Namespace
# ==============
#
# Inside the context there is a special key ruty which gives you access
# to some ruty information:
#
#   ruty.block_start      the string representing a block start ( {% )
#   ruty.block_end        same for block end ( %} )
#   ruty.var_start        same for variable start ( {{ )
#   ruty.var_end          same for variable end ( }} )
#   ruty.comment_start    same for comments ( {# }
#   ruty.comment_end      end comment ends ( #} )
#   ruty.version          the ruty version as string 
#
# Extending Ruty
# ==============
#
# Is very easy. Have a look at the sourcecode... dumdidum. there is no
# documentation ^^


module Ruty
  
  # Returns version of the ruty template engine
  def self.version
    "ruty.rb 0.0.1"
  end
  
  # ruty base exception
  class Exception < ::Exception
  end

  # exception for runtime errors
  class TemplateRuntimeError < Exception
  end

  # exception for syntax errors
  class TemplateSyntaxError < Exception
  end

  # exception to indicate that a template a loader
  # tried to load does not exist.
  class TemplateNotFound < Exception
  end

  # load libraries
  require 'ruty/constants'
  require 'ruty/parser'
  require 'ruty/context'
  require 'ruty/datastructure'
  require 'ruty/loaders'
  require 'ruty/filters'
  require 'ruty/tags'

  # ruty context
  RUTY_CONTEXT = {
    :block_start =>     Constants::BLOCK_START,
    :block_end =>       Constants::BLOCK_END,
    :var_start =>       Constants::VAR_START,
    :var_end =>         Constants::VAR_END,
    :comment_start =>   Constants::COMMENT_START,
    :comment_end =>     Constants::COMMENT_END,
    :version =>         Ruty.version
  }
  
  # template class
  class Template

    # load a template from a sourcecode or nodelist.
    def initialize source
      if source.is_a?(Datastructure::NodeList)
        @nodelist = source
      else
        @nodelist = Parser.new(source).parse
      end
    end

    # render the template. Pass it a hash or hashlike
    # object (must support [] and has_key?) which is
    # used as data storage for the root namespace
    def render namespace
      context = Context.new(namespace)
      context.push(
        :ruty =>      RUTY_CONTEXT,
        :nil =>       nil,
        :true =>      true,
        :false =>     false
      )
      result = ''
      @nodelist.render_node(context, result)
      result
    end
  end
end
