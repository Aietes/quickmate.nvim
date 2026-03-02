return function(t, ctx)
  local quickmate = require 'quickmate'

  local original_notify = vim.notify
  local original_executable = vim.fn.executable
  local original_priority = ctx.state.package_manager_priority
  local original_pm = ctx.state.package_manager
  local captured = {}

  vim.notify = function(message)
    captured[#captured + 1] = tostring(message)
  end

  vim.fn.executable = function(bin)
    if bin == 'pnpm' or bin == 'bun' or bin == 'npm' or bin == 'yarn' then
      return 0
    end
    return original_executable(bin)
  end

  ctx.state.package_manager = nil
  ctx.state.package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' }

  quickmate.run_preset('tsc', { cwd = ctx.root })

  vim.fn.executable = original_executable
  vim.notify = original_notify
  ctx.state.package_manager = original_pm
  ctx.state.package_manager_priority = original_priority

  local saw_missing_pm = false
  for _, msg in ipairs(captured) do
    if msg:match 'no package manager found' then
      saw_missing_pm = true
      break
    end
  end

  t.expect(saw_missing_pm, 'run_preset should fail early when preset command requires a package manager')
end
