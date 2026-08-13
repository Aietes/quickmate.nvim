return function(t)
  local util = require 'quickmate.util'

  t.expect_eq(util.strip_ansi '\27[31merror\27[0m: boom', 'error: boom', 'color codes should be stripped')
  t.expect_eq(util.strip_ansi '\27[1;33mwarn\27[m text', 'warn text', 'multi-param codes should be stripped')
  t.expect_eq(util.strip_ansi 'plain', 'plain', 'plain text should pass through')
  t.expect_eq(util.strip_ansi(nil), '', 'nil should become empty string')
end
