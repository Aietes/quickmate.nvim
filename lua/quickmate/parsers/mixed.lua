local util = require 'quickmate.util'

local M = {}

---@param decoded table
---@return string
local function encode_json(decoded)
  local ok, encoded = pcall(vim.json.encode, decoded)
  if ok and type(encoded) == 'string' then
    return encoded
  end
  return ''
end

---@param ctx quickmate.ParserContext
---@param deps table
---@return quickmate.ParserResult|nil
function M.parse(ctx, deps)
  local candidates = util.extract_json_candidates(util.strip_ansi(ctx.combined))

  local all_items = {}
  local matched_payload = false

  local ts_parsed = deps.ts.parse(ctx)
  if ts_parsed and ts_parsed.items then
    matched_payload = true
    vim.list_extend(all_items, ts_parsed.items)
  end

  for _, candidate in ipairs(candidates) do
    local decoded = util.decode_json_candidate(candidate)
    if decoded then
      if deps.oxlint.is_payload(decoded) then
        matched_payload = true
        local encoded = encode_json(decoded)
        local parsed = deps.oxlint.parse_json({
          cmd = ctx.cmd,
          title = ctx.title,
          cwd = ctx.cwd,
          stdout = encoded,
          stderr = '',
          combined = encoded,
          errorformat = ctx.errorformat,
        })
        if parsed and parsed.items then
          vim.list_extend(all_items, parsed.items)
        end
      elseif deps.eslint.is_payload(decoded) then
        matched_payload = true
        local encoded = encode_json(decoded)
        local parsed = deps.eslint.parse_json({
          cmd = ctx.cmd,
          title = ctx.title,
          cwd = ctx.cwd,
          stdout = encoded,
          stderr = '',
          combined = encoded,
          errorformat = ctx.errorformat,
        })
        if parsed and parsed.items then
          vim.list_extend(all_items, parsed.items)
        end
      end
    end
  end

  if not matched_payload then
    if util.strip_ansi(ctx.combined):match '^%s*$' then
      return { items = {}, ok = true }
    end
    return nil
  end
  return { items = util.normalize_items(all_items, ctx.cwd), ok = true }
end

return M
