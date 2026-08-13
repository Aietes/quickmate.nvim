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

  -- keep the straggler sleep short: the timeout SIGTERM hits the shell, but a
  -- surviving child holds the stdout pipe open and delays the callback until
  -- it exits, so the wait below must comfortably outlast the full sleep
  quickmate.run("printf 'file.lua:1:1: partial\\n'; sleep 2", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    timeout_ms = 200,
    open_quickfix = 'never',
    on_complete = function(res)
      result = res
      done = true
    end,
  })

  local ok = vim.wait(8000, function()
    return done
  end, 20)

  vim.notify = original_notify

  t.expect(ok, 'timeout test should complete')
  if not result then
    error('timeout test expected result', 0)
  end
  t.expect_eq(#result.items, 0, 'timed out run should not parse partial output into items')

  local saw_timeout = false
  for _, msg in ipairs(captured) do
    if msg:match 'timed out after 200ms' then
      saw_timeout = true
      break
    end
  end
  t.expect(saw_timeout, 'timed out run should report the timeout')
end
