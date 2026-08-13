return function(t, ctx)
  if vim.fn.executable('npm') ~= 1 then
    return
  end

  local runner = require 'quickmate.runner'

  local root = vim.fn.tempname()
  local nested = vim.fs.joinpath(root, 'packages', 'app')
  vim.fn.mkdir(nested, 'p')
  vim.fn.writefile({ '{}' }, vim.fs.joinpath(root, 'package-lock.json'))
  vim.fn.writefile({ '{}' }, vim.fs.joinpath(nested, 'package.json'))

  -- ensure the priority fallback cannot mask a detection failure
  local original_priority = ctx.state.package_manager_priority
  ctx.state.package_manager_priority = {}

  local detected = runner._detect_package_manager(nested)

  ctx.state.package_manager_priority = original_priority
  vim.fn.delete(root, 'rf')

  t.expect_eq(detected, 'npm', 'lockfile at workspace root should be found from nested package dir')
end
