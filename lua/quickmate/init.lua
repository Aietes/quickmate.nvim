local commands = require 'quickmate.commands'
local parser_registry = require 'quickmate.parsers'
local presets = require 'quickmate.presets'
local runner = require 'quickmate.runner'
local state_mod = require 'quickmate.state'
local version = require 'quickmate.version'

local M = {}
M.VERSION = version.current

---@alias quickmate.OpenQuickfixPolicy 'on_items'|'always'|'never'

---@class quickmate.SetupOpts
---@field open_quickfix? quickmate.OpenQuickfixPolicy
---@field default_errorformat? string
---@field commands? boolean
---@field package_manager? string
---@field package_manager_priority? string[]
---@field presets? table<string, quickmate.PresetOpts>

---@class quickmate.RunOpts
---@field title? string
---@field cwd? string
---@field env? table<string, string>
---@field timeout_ms? integer
---@field package_manager? string
---@field parser? string|(fun(ctx: quickmate.ParserContext): quickmate.ParserResult)|nil
---@field errorformat? string
---@field open_quickfix? quickmate.OpenQuickfixPolicy
---@field on_complete? fun(result: quickmate.RunResult)

---@class quickmate.PresetCmdCtx
---@field package_manager string
---@field cwd string

---@class quickmate.PresetOpts
---@field cmd string|fun(ctx: quickmate.PresetCmdCtx): string
---@field title? string
---@field parser? string|(fun(ctx: quickmate.ParserContext): quickmate.ParserResult)|nil
---@field errorformat? string
---@field cwd? string
---@field env? table<string, string>
---@field timeout_ms? integer
---@field open_quickfix? quickmate.OpenQuickfixPolicy

---@class quickmate.ParserContext
---@field cmd string
---@field title string
---@field cwd string
---@field stdout string
---@field stderr string
---@field combined string
---@field errorformat string

---@class quickmate.ParserResult
---@field items table[]
---@field ok? boolean
---@field message? string

---@class quickmate.RunResult
---@field cmd string
---@field title string
---@field code integer
---@field signal integer|nil
---@field stdout string
---@field stderr string
---@field combined string
---@field items table[]
---@field parser_used string
---@field duration_ms integer

local state = state_mod.state
local known_package_managers = state_mod.known_package_managers

---@param policy string|nil
---@return boolean
local function is_valid_open_quickfix(policy)
  return policy == 'on_items' or policy == 'always' or policy == 'never'
end

---@param cmd string
---@param opts quickmate.RunOpts|nil
function M.run(cmd, opts)
  runner.run(cmd, opts)
end

---@return string
function M.version()
  return M.VERSION
end

---@param name string
---@param opts quickmate.RunOpts|nil
function M.run_script(name, opts)
  runner.run_script(name, opts)
end

---@param name string
---@param opts quickmate.RunOpts|nil
function M.run_preset(name, opts)
  runner.run_preset(name, opts)
end

---@param name string
---@param parser_fn fun(ctx: quickmate.ParserContext): quickmate.ParserResult|nil
function M.register_parser(name, parser_fn)
  if type(name) ~= 'string' or name == '' then
    return
  end
  if type(parser_fn) ~= 'function' then
    return
  end
  state.parsers[name] = parser_fn
end

---@param name string
---@param preset_opts quickmate.PresetOpts
function M.register_preset(name, preset_opts)
  if type(name) ~= 'string' or name == '' then
    return
  end
  if type(preset_opts) ~= 'table' then
    return
  end
  state.presets[name] = preset_opts
end

---@param opts quickmate.SetupOpts|nil
function M.setup(opts)
  opts = opts or {}
  state_mod.reset_config()

  parser_registry.register_builtin_parsers(state)
  presets.register_builtin_presets(state)

  if is_valid_open_quickfix(opts.open_quickfix) then
    state.open_quickfix = opts.open_quickfix
  end
  if type(opts.default_errorformat) == 'string' and opts.default_errorformat ~= '' then
    state.default_errorformat = opts.default_errorformat
  end
  state.commands = opts.commands ~= false
  if type(opts.package_manager) == 'string' and known_package_managers[opts.package_manager] then
    state.package_manager = opts.package_manager
  end
  if type(opts.package_manager_priority) == 'table' and #opts.package_manager_priority > 0 then
    local priority = {}
    for _, pm in ipairs(opts.package_manager_priority) do
      if type(pm) == 'string' and known_package_managers[pm] then
        priority[#priority + 1] = pm
      end
    end
    if #priority > 0 then
      state.package_manager_priority = priority
    end
  end

  if type(opts.presets) == 'table' then
    for name, preset in pairs(opts.presets) do
      M.register_preset(name, preset)
    end
  end

  if state.commands then
    commands.register(state, M)
  end
end

return M
