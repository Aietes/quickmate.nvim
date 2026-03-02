[![Version](https://img.shields.io/github/v/tag/Aietes/quickmate.nvim?style=for-the-badge&label=version&sort=semver)](https://github.com/Aietes/quickmate.nvim/tags)
[![Tests](https://img.shields.io/github/actions/workflow/status/Aietes/quickmate.nvim/tests.yml?branch=main&style=for-the-badge&label=tests)](https://github.com/Aietes/quickmate.nvim/actions/workflows/tests.yml)
[![Last Commit](https://img.shields.io/github/last-commit/Aietes/quickmate.nvim?style=for-the-badge)](https://github.com/Aietes/quickmate.nvim/commits/main)
[![Neovim](https://img.shields.io/badge/Neovim-0.10%2B-57A143?style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.io/)
[![License](https://img.shields.io/github/license/Aietes/quickmate.nvim?style=for-the-badge)](https://github.com/Aietes/quickmate.nvim/blob/main/LICENSE)

**quickmate.nvim** provides **project-wide diagnostics** from linters, typecheckers, and analyzers in a **consolidated quickfix list**.

The plugin runs the respective check tool/script asynchronously, parses linter/typecheck/analyzer output, and populates the quickfix list with normalized entries. It is intentionally focused on checks that produce diagnostics across a project:

- linters
- typecheckers
- analyzers

No formatter orchestration, no task-runner complexity — just `command → parser → quickfix`.

> Per-buffer linting and formatter/auto-fix workflows are intentionally out of scope, since they are typically handled by active LSPs via `nvim-lspconfig`, plugins like `nvim-lint` or `none-ls.nvim`, and formatter flows with `conform.nvim`. **quickmate.nvim** aims to complement the existing tools with a simple and quick _project-wide checks_ → _quickfix list_.

## Features

- Async command execution via `vim.system`
- Quickfix-first workflow (`command -> parser -> quickfix`)
- Package manager aware script/exec command building (`pnpm`, `bun`, `npm`, `yarn`)
- Built-in parsers for:
  - `oxlint` JSON and text output
  - `eslint` JSON and text output
  - `tsc` / `nuxt typecheck` text diagnostics
  - `selene` Json2 and quiet output
  - `luacheck` text diagnostics
  - `cargo` JSON from `--message-format=json` diagnostics
  - `errorformat` fallback for generic tools
- Mixed-output parser for scripts that combine multiple tools (for example `nuxt typecheck;oxlint;eslint`)
- Built-in command presets (`oxlint`, `eslint`, `clippy`, `rust`, `tsc`, `nuxt`, `lua`, `selene`, `luacheck`)
- Native `vim.notify` progress and completion messages

> **quickmate.nvim** does not install or configure linters/typecheckers/analyzers for you. Each project is expected to provide its own tools and configuration (for example via `package.json`, `Cargo.toml`, local config files, and installed binaries).

## Installation

### Requirements

- Neovim `0.10+` (uses `vim.system` and modern `vim.fs` APIs)

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'Aietes/quickmate.nvim',
  -- optional: pin to a release tag
  -- version = '*',
  opts = {},
}
```

Sane defaults are provided, so no configuration is strictly necessary. See the [Configuration](#configuration) section for all available options.

Health Check

```vim
:checkhealth quickmate
```

Help docs:

```vim
:help quickmate.nvim
```

## Commands

- `:Check <shell command>` runs an arbitrary shell command and [parses](#parser-strategy) diagnostics
- `:Check @<preset-name>` using a registered or [built-in preset](#built-in-presets)
- `:CheckScript <script-name>` runs a package manager script with [auto-detected](#package-manager-detection) package manager
- `:CheckPreset <name>` runs a registered [preset](#built-in-presets) by name

Examples:

```vim
:Check oxlint
:Check @rust
:Check "pnpm exec nuxt typecheck"
:Check "cargo clippy --message-format=json"
:Check @lua
:CheckScript check
:CheckPreset tsc
```

## Mixed Output Checks

For combined project checks, prefer one script that runs typecheck + multiple linters and let `:CheckScript` parse all diagnostics into one quickfix list.

Example `package.json`:

```json
{
  "scripts": {
    "check": "nuxt typecheck;oxlint . --format=json;eslint . -f json"
  }
}
```

Then run:

```vim
:CheckScript check
```

Key principles for mixed output checks:

- `;` runs all steps even if one step fails, so you still get a complete quickfix list
- prefer JSON output for more reliable parsing when available, e.g. from `oxlint` and `eslint`
- `mixed_lint_json` merges typecheck text diagnostics with embedded linter JSON payloads

## Built-in Presets

- `oxlint`: Fast JavaScript/TypeScript linter from the Oxc project.  
  Example command: `pnpm exec oxlint --format json .`  
  https://oxc.rs/docs/guide/usage/linter.html
- `eslint`: Widely used JavaScript/TypeScript linter with extensive plugin ecosystem.  
  Example command: `pnpm exec eslint -f json .`  
  https://eslint.org/
- `clippy`: Rust lint collection for catching common mistakes and improving code quality.  
  Example command: `cargo clippy --message-format=json`  
  https://doc.rust-lang.org/clippy/
- `rust`: Rust compiler check mode (`cargo check`) for fast compile-time diagnostics without building binaries.  
  Example command: `cargo check --message-format=json`  
  https://doc.rust-lang.org/cargo/commands/cargo-check.html
- `tsc`: TypeScript compiler typecheck mode (`--noEmit`) for TS diagnostics only.  
  Example command: `pnpm exec tsc --noEmit --pretty false`  
  https://www.typescriptlang.org/docs/handbook/compiler-options.html
- `nuxt`: Nuxt-specific typecheck command for Vue/Nuxt projects.  
  Example command: `pnpm exec nuxt typecheck`  
  https://nuxt.com/docs/api/commands/typecheck
- `lua`: Lua diagnostics via `selene` (default Lua preset).  
  Example command: `selene --display-style Json2 --allow-warnings lua tests`  
  https://kampfkarren.github.io/selene/
  Uses project `selene.toml` + `vim.toml` so Neovim `vim.*` globals are recognized.
- `selene`: Explicit selene preset (same command as `lua`).  
  Example command: `selene --display-style Json2 --allow-warnings lua tests`  
  https://kampfkarren.github.io/selene/
- `luacheck`: Optional luacheck preset for luacheck-style output.  
  Example command: `luacheck lua tests`  
  https://github.com/lunarmodules/luacheck

## Configuration

For `lazy.nvim`:

```lua
opts = {
  open_quickfix = 'on_items', -- 'on_items' | 'always' | 'never'
  default_errorformat = vim.o.errorformat,
  commands = true,
  package_manager = nil, -- 'pnpm' | 'bun' | 'npm' | 'yarn' | nil (auto)
  package_manager_priority = { 'pnpm', 'bun', 'npm', 'yarn' },
  presets = {
    check = {
      cmd = 'pnpm run check',
      parser = 'mixed_lint_json',
      title = 'project check',
    },
  },
}
```

For manual (non-`lazy.nvim`) configuration, call `require('quickmate').setup(...)` and pass options table.

## Package Manager Detection

For JS/TS commands (`:CheckScript` and manager-aware presets like `@tsc`/`@nuxt`), `quickmate.nvim` resolves a package manager in this order:

1. Per-run override (`opts.package_manager`)
2. Global setup override (`setup({ package_manager = ... })`)
3. Project lockfiles:
   - `pnpm-lock.yaml` -> `pnpm`
   - `bun.lock` / `bun.lockb` -> `bun`
   - `package-lock.json` -> `npm`
   - `yarn.lock` -> `yarn`
4. First executable from `package_manager_priority` (default: `pnpm`, `bun`, `npm`, `yarn`)

Command translation examples:

- `run_script('check')` with `pnpm` -> `pnpm run check`
- `run_script('check')` with `bun` -> `bun run check`
- `@tsc` with `npm` -> `npx --no-install tsc --noEmit --pretty false`

## API

```lua
local check = require('quickmate')

check.VERSION
check.version()
check.setup(opts)
check.run(cmd, opts)
check.run_script(name, opts)
check.run_preset(name, opts)
check.register_parser(name, fn)
check.register_preset(name, preset)
```

## Parser Strategy

Parse order:

1. Explicit parser from `opts.parser`
2. Auto-detected parser by command content
3. Fallback parser `efm` (`errorformat`)

`mixed_lint_json` merges:

- TypeScript/Nuxt text diagnostics
- Embedded `oxlint` JSON payloads
- Embedded `eslint` JSON payloads

This allows one `:CheckScript check` command to collect all issues into one quickfix list.

## Notifications

Native `vim.notify` is used for:

- Running spinner while command executes
- Completion status (`no issues`, `<n> issue(s)`)
- Parser fallback warnings
- Execution/parser errors

## Extending

Register custom parsers:

```lua
require('quickmate').register_parser('my_tool', function(ctx)
  -- return { items = {...}, ok = true } or nil
end)
```

Register custom presets:

```lua
require('quickmate').register_preset('my_check', {
  cmd = 'pnpm run my:check',
  parser = 'mixed_lint_json',
  title = 'my check',
})
```

## Contributing Presets

Additional presets are welcome.

When opening a PR for a new preset, include:

- the tool command(s) for supported package managers (if JS/TS ecosystem)
- expected output format and parser used
- one real output sample (error and/or warning)
- a short note explaining why the preset fits the plugin scope (diagnostics-oriented checks)

Prefer presets that are:

- diagnostics-focused (lint/typecheck/analyzer)
- stable across common project setups
- parser-backed (structured JSON preferred when available)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development workflow and release steps.

### Design Principles

- Prefer native Neovim APIs (`vim.system`, `vim.fs.root`, quickfix APIs)
- Keep behavior predictable and quickfix-focused
- Avoid task-runner orchestration complexity
- Keep parser modules composable and small

### Testing

Run the built-in parser/registration tests with headless Neovim:

```bash
./scripts/test.sh
```

### Versioning

`quickmate.nvim` uses SemVer and Git tags (standard for Neovim plugins).

- Source-of-truth runtime version: `require('quickmate').VERSION`
- Current version file: `VERSION`
- Release tags should be `vX.Y.Z` (for example `v0.1.0`)
- Repeatable release script: `./scripts/release.sh X.Y.Z`

Create a release (updates version files, runs tests, commits, tags):

```bash
./scripts/release.sh 0.1.1
git push origin main
git push origin v0.1.1
```

Preview release actions without changes:

```bash
./scripts/release.sh 0.1.1 --dry-run
```

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).
