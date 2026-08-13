return function(t, ctx)
  -- fixture captured from oxlint 1.x piped output (2026-08)
  local combined = table.concat({
    '',
    '  ! eslint(no-unused-expressions): Expected expression to be used',
    '   ,-[app/app.vue:7:1]',
    ' 6 | })',
    ' 7 | error',
    '   : ^^^^^',
    ' 8 | </script>',
    "   `----",
    '  help: Consider using this expression or removing it',
    '',
    'Found 1 warning and 0 errors.',
    'Finished in 15ms on 590 files with 127 rules using 18 threads.',
  }, '\n')

  local cwd = t.abs(ctx.root .. '/tmp-oxlint')
  local parsed = ctx.state.parsers.oxlint({
    cmd = 'pnpm exec oxlint .',
    title = 'oxlint',
    cwd = cwd,
    stdout = combined,
    stderr = '',
    combined = combined,
    errorformat = vim.o.errorformat,
  })

  t.expect(type(parsed) == 'table', 'oxlint text output should parse')
  t.expect_eq(#parsed.items, 1, 'oxlint text output should produce one item')

  local item = parsed.items[1]
  t.expect_eq(item.filename, t.abs(vim.fs.joinpath(cwd, 'app/app.vue')), 'oxlint text item should resolve filename')
  t.expect_eq(item.lnum, 7, 'oxlint text item should keep line')
  t.expect_eq(item.col, 1, 'oxlint text item should keep column')
  t.expect_eq(item.type, 'W', 'the ! mark should map to warning')
  t.expect(item.text:find('no-unused-expressions', 1, true) ~= nil, 'oxlint text item should keep the rule name')
end
