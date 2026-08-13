return function(t, ctx)
  local cwd = t.abs(ctx.root .. '/tmp-cargo')
  local message = vim.json.encode({
    reason = 'compiler-message',
    message = {
      level = 'error',
      message = 'mismatched types',
      code = { code = 'E0308' },
      spans = {
        { file_name = 'src/main.rs', line_start = 7, column_start = 9, line_end = 7, column_end = 14, is_primary = true },
      },
    },
  })
  local noise = vim.json.encode({ reason = 'build-finished', success = false })
  local parser_ctx = {
    cmd = 'cargo check --message-format=json',
    title = 'cargo check',
    cwd = cwd,
    stdout = '',
    stderr = '',
    combined = table.concat({ message, noise, 'warning: build failed' }, '\n'),
    errorformat = vim.o.errorformat,
  }

  local parsed = ctx.state.parsers.cargo_json(parser_ctx)
  t.expect(type(parsed) == 'table', 'cargo_json should parse compiler messages')
  t.expect_eq(#parsed.items, 1, 'cargo_json should produce one item and skip non-diagnostic lines')

  local item = parsed.items[1]
  t.expect_eq(item.filename, t.abs(vim.fs.joinpath(cwd, 'src/main.rs')), 'cargo_json should normalize filename to absolute path')
  t.expect_eq(item.lnum, 7, 'cargo_json should keep primary span line')
  t.expect_eq(item.col, 9, 'cargo_json should keep primary span column')
  t.expect_eq(item.type, 'E', 'cargo_json should map error level to E')
  t.expect(item.text:find('E0308', 1, true) ~= nil, 'cargo_json should append the diagnostic code')
  t.expect(item.text:find('%[cargo%]') ~= nil, 'cargo_json should tag item source')
end
