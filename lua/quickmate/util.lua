local M = {}

---@param text string|nil
---@return string
function M.strip_ansi(text)
  local stripped = (text or ''):gsub('\27%[[0-9;?]*[ -/]*[@-~]', '')
  return stripped
end

---@param text string
---@return string
function M.strip_newlines(text)
  local normalized = text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  return normalized
end

---@param cmd string
---@return string
function M.normalize_command_input(cmd)
  -- join lines but keep inner spacing intact: quoted arguments may contain
  -- significant runs of whitespace
  local trimmed = (cmd or ''):gsub('[\r\n]+', ' '):gsub('^%s+', ''):gsub('%s+$', '')
  local first = trimmed:sub(1, 1)
  local last = trimmed:sub(-1)
  if #trimmed >= 2 and ((first == '"' and last == '"') or (first == "'" and last == "'")) then
    return trimmed:sub(2, -2)
  end
  return trimmed
end

---@param value any
---@return any
function M.from_json(value)
  if value == vim.NIL then
    return nil
  end
  return value
end

---@param text string
---@return string
function M.normalize_json_like(text)
  local normalized = text:gsub(',%s*([}%]])', '%1')
  return normalized
end

---@param text string
---@param start_idx integer
---@return string|nil
---@return integer|nil
local function extract_json_value(text, start_idx)
  local first = text:sub(start_idx, start_idx)
  if first ~= '{' and first ~= '[' then
    return nil, nil
  end

  local stack = { first }
  local in_string = false
  local escaped = false

  for i = start_idx + 1, #text do
    local c = text:sub(i, i)
    if in_string then
      if escaped then
        escaped = false
      elseif c == '\\' then
        escaped = true
      elseif c == '"' then
        in_string = false
      end
    else
      if c == '"' then
        in_string = true
      elseif c == '{' or c == '[' then
        stack[#stack + 1] = c
      elseif c == '}' then
        if stack[#stack] ~= '{' then
          return nil, nil
        end
        stack[#stack] = nil
        if #stack == 0 then
          return text:sub(start_idx, i), i
        end
      elseif c == ']' then
        if stack[#stack] ~= '[' then
          return nil, nil
        end
        stack[#stack] = nil
        if #stack == 0 then
          return text:sub(start_idx, i), i
        end
      end
    end
  end

  return nil, nil
end

---@param text string
---@return table[]
function M.extract_json_candidates(text)
  local candidates = {}
  local i = 1
  while i <= #text do
    local ch = text:sub(i, i)
    if ch == '{' or ch == '[' then
      local value, end_idx = extract_json_value(text, i)
      if value and end_idx then
        candidates[#candidates + 1] = value
        i = end_idx + 1
      else
        i = i + 1
      end
    else
      i = i + 1
    end
  end
  return candidates
end

---@param json_text string
---@return table|nil
function M.decode_json_candidate(json_text)
  local ok, decoded = pcall(vim.json.decode, json_text)
  if ok and type(decoded) == 'table' then
    return decoded
  end

  ok, decoded = pcall(vim.json.decode, M.normalize_json_like(json_text))
  if ok and type(decoded) == 'table' then
    return decoded
  end
  return nil
end

---@param path string
---@return boolean
local function is_absolute_path(path)
  if path:match '^/' then
    return true
  end
  if path:match '^%a:[/\\]' then
    return true
  end
  return false
end

---@param item table
---@param base_cwd string|nil
---@return table
local function normalize_item(item, base_cwd)
  local filename = item.filename
  -- items parsed via getqflist({ lines = ..., efm = ... }) carry bufnr, not filename
  if (not filename or filename == '') and type(item.bufnr) == 'number' and item.bufnr > 0 then
    local bufname = vim.api.nvim_buf_get_name(item.bufnr)
    if bufname ~= '' then
      filename = vim.fn.fnamemodify(bufname, ':.')
    end
  end
  if filename and filename ~= '' then
    if not is_absolute_path(filename) and type(base_cwd) == 'string' and base_cwd ~= '' then
      filename = vim.fs.joinpath(base_cwd, filename)
    end
    filename = vim.fn.fnamemodify(filename, ':p')
  end

  return {
    filename = filename,
    lnum = tonumber(item.lnum) or 1,
    col = tonumber(item.col) or 1,
    end_lnum = tonumber(item.end_lnum) or nil,
    end_col = tonumber(item.end_col) or nil,
    text = item.text or '',
    type = item.type or '',
    user_data = item.user_data,
  }
end

---@param source string
---@param item table
---@return table
function M.tag_item_source(source, item)
  local text = item.text or ''
  item.text = string.format('[%s] %s', source, text)
  item.user_data = vim.tbl_extend('force', item.user_data or {}, { source = source })
  return item
end

---@param items table[]
---@param base_cwd string|nil
---@return table[]
function M.normalize_items(items, base_cwd)
  local normalized = {}
  for _, item in ipairs(items) do
    normalized[#normalized + 1] = normalize_item(item, base_cwd)
  end
  return normalized
end

---@param severity integer|string|nil
---@return string
function M.qf_type_from_severity(severity)
  if severity == 2 or severity == 'error' then
    return 'E'
  end
  if severity == 1 or severity == 'warning' or severity == 'warn' then
    return 'W'
  end
  return 'I'
end

---@param output string
---@return string
function M.first_nonempty_line(output)
  for line in (output or ''):gmatch('[^\r\n]+') do
    local trimmed = M.strip_newlines(line)
    if trimmed ~= '' then
      return trimmed
    end
  end
  return ''
end

return M
