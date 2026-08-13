return function(t)
  local quickmate = require 'quickmate'

  local done_slow, done_fast = false, false

  quickmate.run("sh -c 'sleep 0.4; printf \"slow.lua:1:1: stale\\n\"'", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    open_quickfix = 'never',
    on_complete = function()
      done_slow = true
    end,
  })
  quickmate.run("printf 'fast.lua:1:1: fresh\\n'", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    open_quickfix = 'never',
    on_complete = function()
      done_fast = true
    end,
  })

  local ok = vim.wait(4000, function()
    return done_slow and done_fast
  end, 20)

  t.expect(ok, 'overlapping runs test should complete')
  local qf = vim.fn.getqflist()
  t.expect_eq(#qf, 1, 'quickfix should hold exactly the newest run result')
  t.expect(qf[1].text:match 'fresh' ~= nil, 'stale slow run must not clobber the newer run result')

  vim.fn.setqflist({}, 'r')
end
