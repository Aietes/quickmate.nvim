local M = {}

M.known_package_managers = {
  pnpm = true,
  bun = true,
  npm = true,
  yarn = true,
}

---@class quickmate.State
---@field open_quickfix quickmate.OpenQuickfixPolicy
---@field default_errorformat string
---@field commands boolean
---@field commands_registered boolean
---@field package_manager string|nil
---@field package_manager_priority string[]
---@field parsers table<string, fun(ctx: quickmate.ParserContext): quickmate.ParserResult|nil>
---@field presets table<string, quickmate.PresetOpts>
M.state = {
  open_quickfix = 'on_items',
  default_errorformat = vim.o.errorformat,
  commands = true,
  commands_registered = false,
  package_manager = nil,
  package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' },
  parsers = {},
  presets = {},
}

function M.reset_config()
  local commands_registered = M.state.commands_registered
  M.state.open_quickfix = 'on_items'
  M.state.default_errorformat = vim.o.errorformat
  M.state.commands = true
  M.state.package_manager = nil
  M.state.package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' }
  M.state.parsers = {}
  M.state.presets = {}
  M.state.commands_registered = commands_registered
end

return M
