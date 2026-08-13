local util = require 'quickmate.util'

local M = {}

---@param state quickmate.State
---@param api table
function M.register(state, api)
  if state.commands_registered then
    return
  end
  state.commands_registered = true

  local function package_json_script_complete(arg_lead)
    local cwd = vim.fs.root(0, { 'package.json', '.git' }) or vim.uv.cwd()
    local package_json_path = vim.fs.joinpath(cwd, 'package.json')
    if vim.fn.filereadable(package_json_path) == 0 then
      return {}
    end

    local ok_read, lines = pcall(vim.fn.readfile, package_json_path)
    if not ok_read then
      return {}
    end

    local ok_json, pkg = pcall(vim.json.decode, table.concat(lines, '\n'))
    if not ok_json or type(pkg) ~= 'table' or type(pkg.scripts) ~= 'table' then
      return {}
    end

    local suggestions = {}
    for script_name, _ in pairs(pkg.scripts) do
      if script_name:find(arg_lead, 1, true) == 1 then
        suggestions[#suggestions + 1] = script_name
      end
    end
    table.sort(suggestions)
    return suggestions
  end

  local function preset_complete(arg_lead)
    local suggestions = {}
    for name, _ in pairs(state.presets) do
      if name:find(arg_lead, 1, true) == 1 then
        suggestions[#suggestions + 1] = name
      end
    end
    table.sort(suggestions)
    return suggestions
  end

  vim.api.nvim_create_user_command('Check', function(args)
    local arg = util.normalize_command_input(args.args or '')
    if arg:sub(1, 1) == '@' then
      local preset_name = arg:sub(2)
      if preset_name == '' then
        vim.notify('check: missing preset name after @', vim.log.levels.ERROR)
        return
      end
      api.run_preset(preset_name)
      return
    end
    api.run(arg)
  end, {
    nargs = '+',
    complete = 'shellcmd',
    desc = 'Run a shell command and parse output into quickfix',
  })

  vim.api.nvim_create_user_command('CheckScript', function(args)
    api.run_script(args.args)
  end, {
    nargs = 1,
    complete = package_json_script_complete,
    desc = 'Run package manager script and parse output into quickfix',
  })

  vim.api.nvim_create_user_command('CheckPreset', function(args)
    api.run_preset(args.args)
  end, {
    nargs = 1,
    complete = preset_complete,
    desc = 'Run named check preset and parse output into quickfix',
  })
end

return M
