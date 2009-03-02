# = Ruty Constants
#
# Author:: Armin Ronacher
# 
# Copyright (c) 2006 by Armin Ronacher
#
# You can redistribute it and/or modify it under the terms of the BSD license.

module Ruty::Constants

  # template tags.
  # The ruty parser uses the values here to verify which token it
  # should use. It checks for the token types in the order block,
  # var, comment, text. If for example comment is {{# and block is
  # {{, comment will never match because block is matched first.
  BLOCK_START = '{%'
  BLOCK_END = '%}'
  VAR_START = '{{'
  VAR_END = '}}'
  COMMENT_START = '{#'
  COMMENT_END = '#}'

end
