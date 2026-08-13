return function(t)
  local quickmate = require 'quickmate'

  local original_notify = vim.notify
  local captured = {}
  vim.notify = function(message)
    captured[#captured + 1] = tostring(message)
  end

  local done = false
  ---@type quickmate.RunResult|nil
  local result = nil

  quickmate.run('true', {
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

  vim.notify = original_notify

  t.expect(ok, 'clean ts run test should complete')
  if not result then
    error('clean ts run test expected result', 0)
  end
  t.expect_eq(result.parser_used, 'ts_text', 'clean ts run should keep ts_text parser')
  t.expect_eq(#result.items, 0, 'clean ts run should produce no items')
  for _, msg in ipairs(captured) do
    t.expect(not msg:match 'parser failed', 'clean ts run should not warn about parser fallback: ' .. msg)
  end
end
