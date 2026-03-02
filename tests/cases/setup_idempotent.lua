return function(t)
  local quickmate = require 'quickmate'
  local state = require('quickmate.state').state

  quickmate.setup({
    commands = false,
    package_manager = 'npm',
    package_manager_priority = { 'npm' },
    presets = {
      first_only = { cmd = 'echo first' },
    },
  })

  t.expect_eq(state.package_manager, 'npm', 'setup should apply initial package manager')
  t.expect_eq(state.package_manager_priority, { 'npm' }, 'setup should apply initial package manager priority')
  t.expect(type(state.presets.first_only) == 'table', 'setup should register initial custom preset')

  quickmate.setup({
    commands = false,
    package_manager = 'pnpm',
    package_manager_priority = { 'pnpm', 'yarn' },
    presets = {
      second_only = { cmd = 'echo second' },
    },
  })

  t.expect_eq(state.package_manager, 'pnpm', 'setup should overwrite package manager on subsequent calls')
  t.expect_eq(
    state.package_manager_priority,
    { 'pnpm', 'yarn' },
    'setup should overwrite package manager priority on subsequent calls'
  )
  t.expect(state.presets.first_only == nil, 'setup should not retain stale custom presets from prior calls')
  t.expect(type(state.presets.second_only) == 'table', 'setup should apply latest custom presets')
  t.expect(type(state.presets.tsc) == 'table', 'setup should still include builtin presets')

  quickmate.setup({ commands = false })

  t.expect(state.package_manager == nil, 'setup with no package manager should clear previous package manager override')
  t.expect(state.presets.second_only == nil, 'setup with no custom presets should clear previous custom presets')
end
