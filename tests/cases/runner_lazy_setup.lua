return function(t, ctx)
  local quickmate = require 'quickmate'

  local original_notify = vim.notify
  local original_parsers = ctx.state.parsers
  local captured = {}

  ctx.state.parsers = {}
  vim.notify = function(message, level, opts)
    captured[#captured + 1] = tostring(message)
    if level == vim.log.levels.ERROR and opts and opts.title == 'quickmate tests' then
      original_notify(message, level, opts)
    end
  end

  local done = false

  quickmate.run("printf 'oops\\n'", {
    parser = 'efm',
    errorformat = '%m',
    open_quickfix = 'never',
    on_complete = function()
      done = true
    end,
  })

  local ok = vim.wait(2000, function()
    return done
  end, 20)

  vim.notify = original_notify

  t.expect(ok, 'runner lazy setup test should complete')
  local saw_crash = false
  for _, msg in ipairs(captured) do
    if msg:match 'parser crashed' then
      saw_crash = true
      break
    end
  end
  t.expect(not saw_crash, 'runner lazy setup should not emit parser crashed notification')
  t.expect(type(ctx.state.parsers.efm) == 'function', 'runner lazy setup should register efm parser on demand')

  ctx.state.parsers = original_parsers
end
