return function(t, ctx)
  local quickmate = require 'quickmate'
  local state_mod = require 'quickmate.state'

  -- simulate a fresh session where the user registers extras before setup()
  state_mod.reset_config()
  local custom_calls = 0
  quickmate.register_parser('custom_pre_setup', function()
    custom_calls = custom_calls + 1
    return { items = {}, ok = true }
  end)
  quickmate.register_preset('custom_pre_setup', { cmd = 'true', parser = 'custom_pre_setup' })

  local done = false
  ---@type quickmate.RunResult|nil
  local result = nil
  quickmate.run("printf 'file.lua:1:1: boom\\n'", {
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

  t.expect(ok, 'pre-setup registration test should complete')
  t.expect(type(ctx.state.parsers.efm) == 'function', 'builtin parsers should register despite early custom registration')
  t.expect(ctx.state.presets.tsc ~= nil, 'builtin presets should register despite early custom registration')
  t.expect(type(ctx.state.parsers.custom_pre_setup) == 'function', 'early custom parser should survive builtin registration')
  t.expect(ctx.state.presets.custom_pre_setup ~= nil, 'early custom preset should survive builtin registration')
  if not result then
    error('pre-setup registration test expected result', 0)
  end
  t.expect_eq(#result.items, 1, 'efm parsing should work without setup()')

  -- restore the suite's configured state for subsequent test files
  quickmate.setup({ commands = false })
end
