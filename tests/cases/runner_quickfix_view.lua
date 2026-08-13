return function(t)
  local quickmate = require 'quickmate'

  -- 1) trouble.nvim available: open via stubbed trouble instead of copen
  local trouble_calls = {}
  package.loaded['trouble'] = {
    open = function(mode)
      trouble_calls[#trouble_calls + 1] = mode
    end,
  }

  local done = false
  quickmate.run("printf 'file.lua:1:1: boom\\n'", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    open_quickfix = 'always',
    quickfix_view = 'trouble',
    on_complete = function()
      done = true
    end,
  })

  local ok = vim.wait(2000, function()
    return done
  end, 20)

  t.expect(ok, 'quickfix_view trouble test should complete')
  t.expect_eq(#trouble_calls, 1, 'trouble.open should be called once')
  t.expect_eq(trouble_calls[1], 'qflist', 'trouble.open should use the v3 qflist mode')
  t.expect_eq(vim.fn.getqflist({ winid = 0 }).winid, 0, 'quickfix window should not open when trouble handles the view')

  -- 2) trouble.nvim unavailable: warn once and fall back to the quickfix window
  package.loaded['trouble'] = nil

  local original_notify = vim.notify
  local captured = {}
  vim.notify = function(message)
    captured[#captured + 1] = tostring(message)
  end

  done = false
  quickmate.run("printf 'file.lua:1:1: boom\\n'", {
    parser = 'efm',
    errorformat = '%f:%l:%c: %m',
    open_quickfix = 'always',
    quickfix_view = 'trouble',
    on_complete = function()
      done = true
    end,
  })

  ok = vim.wait(2000, function()
    return done
  end, 20)

  vim.notify = original_notify

  t.expect(ok, 'quickfix_view fallback test should complete')
  t.expect(vim.fn.getqflist({ winid = 0 }).winid ~= 0, 'quickfix window should open as fallback without trouble')

  local saw_warning = false
  for _, msg in ipairs(captured) do
    if msg:match 'trouble%.nvim is unavailable' then
      saw_warning = true
      break
    end
  end
  t.expect(saw_warning, 'fallback should warn that trouble.nvim is unavailable')

  vim.cmd 'cclose'
end
