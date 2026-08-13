return function(t)
  local util = require 'quickmate.util'

  t.expect_eq(util.normalize_command_input "  grep 'foo  bar' .  ", "grep 'foo  bar' .", 'inner whitespace must be preserved')
  t.expect_eq(util.normalize_command_input 'echo a\nb', 'echo a b', 'newlines should join with a space')
  t.expect_eq(util.normalize_command_input '"quoted cmd"', 'quoted cmd', 'surrounding quotes should be stripped')
  t.expect_eq(util.normalize_command_input '', '', 'empty input should stay empty')
end
