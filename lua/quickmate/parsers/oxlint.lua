local util = require 'quickmate.util'

local M = {}

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
---@param decoded table
---@return boolean
local function has_lint_shape(decoded)
  local function entry_like(entry)
    return type(entry) == 'table' and (type(entry.messages) == 'table' or type(entry.diagnostics) == 'table')
  end
  if entry_like(decoded) then
    return true
  end
  if vim.islist(decoded) then
    return #decoded == 0 or entry_like(decoded[1])
  end
  return false
end

function M.parse_json(ctx)
  local input = util.strip_ansi(ctx.stdout ~= '' and ctx.stdout or ctx.combined)
  local decoded = util.decode_json_candidate(input)
  if type(decoded) ~= 'table' or not has_lint_shape(decoded) then
    -- arbitrary JSON in the output is not an oxlint report; let text/efm try
    return nil
  end

  local items = {}

  local function add_msg(filename, msg)
    if type(msg) ~= 'table' then
      return
    end
    local resolved_filename = filename
    if type(resolved_filename) ~= 'string' or resolved_filename == '' then
      resolved_filename = msg.filename
    end
    local span = nil
    if type(msg.labels) == 'table' and type(msg.labels[1]) == 'table' then
      span = msg.labels[1].span
    end
    local line = tonumber(msg.line or msg.startLine or (span and span.line)) or 1
    local col = tonumber(msg.column or msg.startColumn or (span and span.column)) or 1
    local message = util.from_json(msg.message) or util.from_json(msg.reason)
    local text = type(message) == 'string' and message or 'oxlint diagnostic'
    local code = util.from_json(msg.code)
    if code ~= nil and code ~= '' then
      text = string.format('%s (%s)', text, tostring(code))
    end
    if type(resolved_filename) == 'string' and resolved_filename ~= '' then
      items[#items + 1] = {
        filename = resolved_filename,
        lnum = line,
        col = col,
        text = text,
        type = util.qf_type_from_severity(msg.severity),
      }
      items[#items] = util.tag_item_source('oxlint', items[#items])
    end
  end

  local function visit(entry)
    if type(entry) ~= 'table' then
      return
    end
    local filename = entry.filePath or entry.filename or entry.path or entry.file

    if type(entry.messages) == 'table' then
      for _, msg in ipairs(entry.messages) do
        add_msg(filename, msg)
      end
    end
    if type(entry.diagnostics) == 'table' then
      for _, msg in ipairs(entry.diagnostics) do
        add_msg(filename, msg)
      end
    end
  end

  if vim.islist(decoded) then
    for _, entry in ipairs(decoded) do
      visit(entry)
    end
  else
    visit(decoded)
  end

  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_text(ctx)
  local lines = vim.split(util.strip_ansi(ctx.combined), '\n', { plain = true })
  local items = {}
  local pending = nil

  for _, line in ipairs(lines) do
    local sev_mark, rule, message = line:match('^%s*([x!])%s+([^:]+):%s+(.+)$')
    if sev_mark and rule and message then
      pending = {
        type = sev_mark == 'x' and 'E' or 'W',
        text = string.format('%s: %s', rule, message),
      }
    else
      local filename, lnum, col = line:match('%[(.-):(%d+):(%d+)%]')
      if pending and filename and lnum and col then
        items[#items + 1] = {
          filename = filename,
          lnum = tonumber(lnum) or 1,
          col = tonumber(col) or 1,
          text = pending.text,
          type = pending.type,
        }
        items[#items] = util.tag_item_source('oxlint', items[#items])
        pending = nil
      end
    end
  end

  if #items == 0 then
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse(ctx)
  return M.parse_json(ctx) or M.parse_text(ctx)
end

---@param decoded table
---@return boolean
function M.is_payload(decoded)
  if type(decoded.diagnostics) == 'table' then
    return true
  end
  if vim.islist(decoded) then
    local first = decoded[1]
    return type(first) == 'table' and type(first.diagnostics) == 'table'
  end
  return false
end

return M
