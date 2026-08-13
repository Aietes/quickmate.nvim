local util = require 'quickmate.util'

local M = {}

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_json(ctx)
  local decoded = util.decode_json_candidate(util.strip_ansi(ctx.stdout ~= '' and ctx.stdout or ctx.combined))
  if type(decoded) ~= 'table' or not M.is_payload(decoded) then
    return nil
  end

  local items = {}
  for _, entry in ipairs(decoded) do
    if type(entry) == 'table' and type(entry.messages) == 'table' then
      for _, msg in ipairs(entry.messages) do
        local filename = entry.filePath or entry.filename
        if type(filename) == 'string' and filename ~= '' and type(msg) == 'table' then
          local rule_id = util.from_json(msg.ruleId)
          local rule = ''
          if rule_id ~= nil and rule_id ~= '' then
            rule = string.format(' (%s)', tostring(rule_id))
          end
          local message = util.from_json(msg.message)
          if type(message) ~= 'string' or message == '' then
            message = 'eslint diagnostic'
          end
          items[#items + 1] = {
            filename = filename,
            lnum = tonumber(msg.line) or 1,
            col = tonumber(msg.column) or 1,
            end_lnum = tonumber(msg.endLine) or nil,
            end_col = tonumber(msg.endColumn) or nil,
            text = message .. rule,
            type = util.qf_type_from_severity(msg.severity),
          }
          items[#items] = util.tag_item_source('eslint', items[#items])
        end
      end
    end
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse_text(ctx)
  local lines = vim.split(util.strip_ansi(ctx.combined), '\n', { plain = true })
  local items = {}
  local current_file = nil

  for _, line in ipairs(lines) do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')

    if trimmed ~= '' and not trimmed:match '^%d+:%d+' and not trimmed:match '^✖' and not trimmed:match '^%d+ problem' then
      if trimmed:match '^/.*' or trimmed:match '^%a:[/\\].*' or trimmed:match '^[%w%._%-%/\\]+%.[%w]+$' then
        current_file = trimmed
      end
    end

    local u_file, u_lnum, u_col, u_msg, u_sev = trimmed:match('^(.+):(%d+):(%d+):%s*(.-)%s*%[(%u)%]$')
    if u_file and u_lnum and u_col and u_msg then
      local sev = (u_sev == 'E') and 'E' or 'W'
      items[#items + 1] = util.tag_item_source('eslint', {
        filename = u_file,
        lnum = tonumber(u_lnum) or 1,
        col = tonumber(u_col) or 1,
        text = u_msg,
        type = sev,
      })
    else
      local lnum, col, sev_txt, msg, rule = trimmed:match('^(%d+):(%d+)%s+(%w+)%s+(.+)%s+([@%w%-%/_]+)$')
      if current_file and lnum and col and sev_txt and msg then
        local sev = sev_txt:lower() == 'error' and 'E' or 'W'
        local text = msg
        if rule and rule ~= '' then
          text = string.format('%s (%s)', msg, rule)
        end
        items[#items + 1] = util.tag_item_source('eslint', {
          filename = current_file,
          lnum = tonumber(lnum) or 1,
          col = tonumber(col) or 1,
          text = text,
          type = sev,
        })
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
  if not vim.islist(decoded) then
    return false
  end
  local first = decoded[1]
  if first == nil then
    -- a clean eslint run emits an empty array
    return true
  end
  return type(first) == 'table' and (first.filePath ~= nil or first.messages ~= nil)
end

return M
