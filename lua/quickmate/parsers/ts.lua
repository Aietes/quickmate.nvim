local util = require 'quickmate.util'

local M = {}

local patterns = {
  '^([~%./%w_%-%s]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^([A-Za-z]:\\[^%(]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^(.+):(%d+):(%d+)%s%-%s*(.*)',
  '^([~%./%w_%-%s]+):(%d+):(%d+)%s*:?%s*(.*)',
  '^([A-Za-z]:\\[^:]+):(%d+):(%d+)%s*:?%s*(.*)',
  '^[^%w%./~%-]*([~%./%w_%-%s]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^[^%w%./~%-]*([A-Za-z]:\\[^%(]+)%((%d+),(%d+)%)%:%s*(.*)',
  '^.-([~%./%w_%-%s]+)%((%d+),(%d+)%)%:%s*(.*)',
}

local location_only_patterns = {
  '^%s*[Ff][Ii][Ll][Ee]%s+([~%./%w_%-%s]+):(%d+):(%d+)%s*$',
  '^%s*[Aa][Tt]%s+([~%./%w_%-%s]+):(%d+):(%d+)%s*$',
  '^%s*([~%./%w_%-%s]+):(%d+):(%d+)%s*$',
}

---@param ctx quickmate.ParserContext
---@return quickmate.ParserResult|nil
function M.parse(ctx)
  if util.strip_ansi(ctx.combined):match '^%s*$' then
    return { items = {}, ok = true }
  end

  local items = {}
  local current = nil
  local pending = nil

  for line in util.strip_ansi(ctx.combined):gmatch('([^\n]*)\n?') do
    local trimmed = line:gsub('^%s+', ''):gsub('%s+$', '')

    if pending then
      local p_file, p_lnum, p_col
      for _, pattern in ipairs(location_only_patterns) do
        p_file, p_lnum, p_col = trimmed:match(pattern)
        if p_file then
          break
        end
      end
      if p_file then
        local item = {
          filename = p_file,
          lnum = tonumber(p_lnum) or 1,
          col = tonumber(p_col) or 1,
          text = pending.text,
          type = pending.type,
        }
        item = util.tag_item_source('tsc', item)
        items[#items + 1] = item
        current = item
        pending = nil
      end
    end

    local file, lnum, col, msg
    for _, pattern in ipairs(patterns) do
      file, lnum, col, msg = line:match(pattern)
      if file then
        break
      end
    end

    if file and msg then
      local lower = msg:lower()
      local diagnostic_like = lower:match '^error'
        or lower:match '^warning'
        or lower:match 'ts%d+'
        or lower:match '^[%u_]+%s+ts%d+'
      if not diagnostic_like then
        file, lnum, col, msg = nil, nil, nil, nil
      end
    end

    if file and msg then
      local lower = msg:lower()
      current = {
        filename = file,
        lnum = tonumber(lnum) or 1,
        col = tonumber(col) or 1,
        text = msg,
        type = (lower:match '^warning' or lower:match '%f[%a]warning%f[%A]') and 'W' or 'E',
      }
      current = util.tag_item_source('tsc', current)
      items[#items + 1] = current
      pending = nil
    elseif trimmed ~= '' then
      local sev, diagnostic = trimmed:match('^[%u_]+%s+([Ee]rror|[Ww]arning)%s*:?%s*(TS%d+:%s*.+)$')
      if not diagnostic then
        diagnostic = trimmed:match('^[%u_]+%s+(TS%d+:%s*.+)$')
      end
      if not diagnostic then
        sev, diagnostic = trimmed:match('^([Ee]rror|[Ww]arning)%s*:?%s*(TS%d+:%s*.+)$')
      end
      if not diagnostic then
        diagnostic = trimmed:match('^(TS%d+:%s*.+)$')
      end
      if diagnostic then
        local lower_sev = (sev or ''):lower()
        pending = {
          text = diagnostic,
          type = lower_sev == 'warning' and 'W' or 'E',
        }
        current = nil
      elseif current and line:match '^%s+%S' then
        current.text = current.text .. ' ' .. line:gsub('^%s+', '')
      else
        current = nil
      end
    elseif current and line:match '^%s+%S' then
      current.text = current.text .. ' ' .. line:gsub('^%s+', '')
    else
      current = nil
    end
  end

  if #items == 0 then
    return nil
  end
  return { items = util.normalize_items(items, ctx.cwd), ok = true }
end

return M
