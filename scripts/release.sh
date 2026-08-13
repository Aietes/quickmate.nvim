#!/usr/bin/env sh
set -eu

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release.sh <version> [--dry-run]

Examples:
  ./scripts/release.sh 0.1.1
  ./scripts/release.sh 0.2.0 --dry-run
EOF
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

VERSION="$1"
DRY_RUN="${2:-}"

case "$DRY_RUN" in
  ""|--dry-run) ;;
  *)
    echo "error: unknown flag '$DRY_RUN'"
    usage
    exit 1
    ;;
esac

if ! printf '%s' "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "error: version must match X.Y.Z (got '$VERSION')"
  exit 1
fi

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

TAG="v$VERSION"
CHANGELOG_HEADER="## [$VERSION] - "

has_changelog_header() {
  grep -Fq "$CHANGELOG_HEADER" CHANGELOG.md
}

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "Releasing quickmate.nvim $VERSION"
  if [ -n "$(git status --porcelain)" ]; then
    echo "[dry-run] Note: working tree is dirty (real release would fail)"
  fi
  if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
    echo "[dry-run] Note: tag '$TAG' already exists (real release would fail)"
  fi
  if ! has_changelog_header; then
    echo "[dry-run] Note: missing changelog section '$CHANGELOG_HEADER...'"
    echo "[dry-run]       Add a section like: ## [$VERSION] - $(date +%Y-%m-%d)"
  fi
  echo "[dry-run] Would run ./scripts/test.sh"
  echo "[dry-run] Would write VERSION"
  echo "[dry-run] Would write lua/quickmate/version.lua"
  echo "[dry-run] Would regenerate doc/tags"
  echo "[dry-run] Would git add VERSION lua/quickmate/version.lua doc/tags"
  echo "[dry-run] Would git commit -m \"chore(release): v$VERSION\""
  echo "[dry-run] Would git tag v$VERSION"
  echo "[dry-run] Done"
  exit 0
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: git working tree is not clean"
  echo "commit or stash changes first"
  exit 1
fi

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "error: tag '$TAG' already exists"
  exit 1
fi

if ! has_changelog_header; then
  echo "error: CHANGELOG.md is missing section '$CHANGELOG_HEADER...'"
  echo "Add a section like: ## [$VERSION] - $(date +%Y-%m-%d)"
  exit 1
fi

echo "Releasing quickmate.nvim $VERSION"

# test before touching version files so a failure leaves the tree clean
./scripts/test.sh

printf '%s\n' "$VERSION" > VERSION

cat > lua/quickmate/version.lua <<EOF
local M = {}

M.current = '$VERSION'

return M
EOF

nvim --headless -u NONE -c 'helptags doc' -c 'qa'

git add VERSION lua/quickmate/version.lua doc/tags
if git diff --cached --quiet; then
  echo "No version file changes to commit; tagging current HEAD."
else
  git commit -m "chore(release): v$VERSION"
fi
git tag "$TAG"

echo "Release commit and tag created."
echo "Next:"
echo "  git push origin main"
echo "  git push origin $TAG"
