return function(t)
  local runner = require 'quickmate.runner'

  t.expect_eq(runner._build_script_command('pnpm', 'check'), "pnpm run 'check'", 'pnpm script command')
  t.expect_eq(runner._build_script_command('bun', 'check'), "bun run 'check'", 'bun script command')
  t.expect_eq(runner._build_script_command('npm', 'check'), "npm run 'check'", 'npm script command')
  t.expect_eq(runner._build_script_command('yarn', 'check'), "yarn 'check'", 'yarn script command')
  t.expect_eq(
    runner._build_script_command('pnpm', 'check; rm -rf /'),
    "pnpm run 'check; rm -rf /'",
    'script names must be shell-escaped'
  )
end
