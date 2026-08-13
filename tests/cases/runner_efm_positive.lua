return function(t)
  local quickmate = require 'quickmate'

  local done = false
  ---@type quickmate.RunResult|nil
  local result = nil

  quickmate.run("printf 'file.lua:3:7: boom\\n'", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    open_quickfix = 'never',
    on_complete = function(res)
      result = res
      done = true
    end,
  })

  local ok = vim.wait(2000, function()
    return done
  end, 20)

  t.expect(ok, 'efm positive test should complete')
  if not result then
    error('efm positive test expected result', 0)
  end
  t.expect_eq(result.parser_used, 'efm', 'efm positive test should use efm parser')
  t.expect_eq(#result.items, 1, 'efm should produce one item for a matching line')
  local item = result.items[1]
  t.expect(type(item.filename) == 'string' and item.filename:match 'file%.lua$' ~= nil, 'efm item should resolve a filename')
  t.expect_eq(item.lnum, 3, 'efm item should keep lnum')
  t.expect_eq(item.col, 7, 'efm item should keep col')
  t.expect_eq(item.text, 'boom', 'efm item should keep message text')
end
