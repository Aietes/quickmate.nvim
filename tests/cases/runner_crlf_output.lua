return function(t)
  local quickmate = require 'quickmate'

  local done = false
  ---@type quickmate.RunResult|nil
  local result = nil

  quickmate.run("printf 'src/app.ts(3,5): error TS2304: Cannot find name x.\\r\\n'", {
    parser = 'ts_text',
    open_quickfix = 'never',
    on_complete = function(res)
      result = res
      done = true
    end,
  })

  local ok = vim.wait(2000, function()
    return done
  end, 20)

  t.expect(ok, 'crlf test should complete')
  if not result then
    error('crlf test expected result', 0)
  end
  t.expect_eq(#result.items, 1, 'crlf output should parse into one item')
  local item = result.items[1]
  t.expect(item.text:find('\r', 1, true) == nil, 'item text must not contain carriage returns')
  t.expect_eq(item.lnum, 3, 'crlf item should keep lnum')
end
