# Changelog

All notable changes to this project are documented in this file.

The format follows Keep a Changelog and this project uses Semantic Versioning.

## [Unreleased]

### Added
- New `quickfix_view` option (`'quickfix' | 'trouble'`, default `'quickfix'`), available in `setup()`, per run, and per preset. With `'trouble'`, results open in [trouble.nvim](https://github.com/folke/trouble.nvim)'s quickfix mode instead of the quickfix window (the quickfix list is still populated either way), with a graceful one-time-warning fallback to the quickfix window when trouble.nvim is not installed.

## [0.1.7] - 2026-03-02

### Changed
- `setup()` is now deterministic/idempotent: configurable state resets on each call before built-ins and user options are applied.
- README restructured and improved for clarity (badges, configuration guidance, consolidated JS/TS package-manager detection, preset consistency).

### Fixed
- Calling runtime APIs before `setup()` no longer triggers parser fallback crashes; built-ins are lazily registered when needed.
- Function-based presets now fail early with a clear error if no supported package manager is available instead of implicitly defaulting to `pnpm`.

## [0.1.6] - 2026-03-01

### Changed
- Plugin renamed from `checkmate.nvim` to `quickmate.nvim`.
- Repository references updated to `Aietes/quickmate.nvim`.
- Help and health entry points now use `quickmate` naming (`:help quickmate.nvim`, `:checkhealth quickmate`).

### Breaking
- Lua module namespace changed from `require('checkmate')` to `require('quickmate')`.
- Help doc file and tags renamed from `checkmate` to `quickmate`.

## [0.1.5] - 2026-03-01

### Added
- Built-in `selene` parser with Json2 and quiet-output support.
- Built-in `selene` preset and `@lua` preset now using selene by default.

### Changed
- Nix dev environment now provides `selene` for Lua linting.
- README/help/contract documentation updated for selene parser and preset behavior.

## [0.1.4] - 2026-03-01

### Changed
- README intro now clearly positions `quickmate.nvim` as a project-wide diagnostics aggregator that complements buffer-focused tools (`nvim-lspconfig`, `nvim-lint`, `none-ls.nvim`, `conform.nvim`).
- Contract documentation now matches implemented parser, preset, and runtime messaging behavior.
- CI workflow now uses the correct `action-setup-vim` inputs for stable/nightly matrix testing.

### Fixed
- `luacheck` parser now treats clean output (`0 warnings / 0 errors`) as a successful parse with zero quickfix items instead of incorrectly falling back to `efm`.

## [0.1.3] - 2026-03-01

### Changed
- Aligned release notes with actual git tags and release commits.
- Release script now requires a matching changelog header (`## [X.Y.Z] - YYYY-MM-DD`) before creating a tag.

## [0.1.2] - 2026-03-01

### Added
- Lua diagnostics support via built-in `luacheck` parser
- Built-in `lua` / `luacheck` presets (`:Check @lua`)
- Nix + direnv development environment support (`.envrc`, `flake.lock`)
- Project luacheck config (`.luacheckrc`) with Neovim globals

### Changed
- Lua preset command now targets project paths (`luacheck lua tests`)
- Runner no longer shows parser-fallback warnings when command is not found
- `efm` fallback entries without file targets are filtered from quickfix
- Core type annotations tightened for cleaner `lua_ls` diagnostics

### Fixed
- TypeScript/Nuxt parser handling for prefixed and multiline diagnostics
- `luacheck` parser handling for both coded and default output formats
- `resolve_cwd` always returns a concrete string path
- Miscellaneous `lua_ls` warnings across runner/parser/test modules

## [0.1.1] - 2026-02-28

### Added
- Release automation script (`scripts/release.sh`)
- Help docs (`doc/quickmate.txt`) and tags
- Health checks (`:checkhealth quickmate`)
- Headless test harness and parser-focused test cases
- Runtime version API (`check.VERSION`, `check.version()`)

## [0.1.0] - 2026-02-28

### Added
- Initial public release of `quickmate.nvim`
- Async command runner with quickfix-first workflow
- Built-in parsers for eslint, oxlint, cargo, ts_text, mixed_lint_json, and efm fallback
- Built-in presets (`oxlint`, `eslint`, `clippy`, `rust`, `tsc`, `nuxt`)
- User commands (`:Check`, `:CheckScript`, `:CheckPreset`)
