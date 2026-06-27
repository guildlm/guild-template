#!/usr/bin/env bash
# Run Crucible eval suites for the {{GUILD_NAME}} specialists.
#
# Usage:
#   {{DOMAIN}}/tools/run_tests.sh [specialist ...]
#
# With no arguments it runs every suite found under {{DOMAIN}}/crucible/.
#
# Environment:
#   CRUCIBLE_DIR   Path to the crucible checkout (default: ../../../crucible).
set -euo pipefail

GUILD_DOMAIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CRUCIBLE_DIR="${CRUCIBLE_DIR:-$GUILD_DOMAIN_DIR/../../crucible}"

if [ "$#" -gt 0 ]; then
  SPECIALISTS=("$@")
else
  SPECIALISTS=()
  for suite in "$GUILD_DOMAIN_DIR"/crucible/*.yaml; do
    [ -e "$suite" ] || continue
    name="$(basename "$suite" .yaml)"
    SPECIALISTS+=("$name")
  done
fi

if [ ! -d "$CRUCIBLE_DIR" ]; then
  echo "error: crucible not found at $CRUCIBLE_DIR (set CRUCIBLE_DIR)" >&2
  exit 1
fi

echo "GuildLM {{GUILD_NAME}} — eval runner"
echo "crucible: $CRUCIBLE_DIR"

status=0
for specialist in "${SPECIALISTS[@]}"; do
  suite="$GUILD_DOMAIN_DIR/crucible/$specialist.yaml"
  if [ ! -f "$suite" ]; then
    echo "skip: no suite for '$specialist' ($suite)" >&2
    status=1
    continue
  fi
  echo
  echo "== $specialist =="
  if command -v crucible >/dev/null 2>&1; then
    ( cd "$CRUCIBLE_DIR" && crucible run "$suite" ) || status=1
  else
    ( cd "$CRUCIBLE_DIR" && python3 -m src.cli run "$suite" ) || status=1
  fi
done

exit "$status"
