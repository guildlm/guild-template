#!/bin/sh
# new_guild.sh — scaffold a new GuildLM guild from the template skeleton.
#
# Copies skeleton/ into a new directory and substitutes the placeholder tokens
# {{GUILD_NAME}}, {{DOMAIN}} and {{SPECIALIST}}. One recipe set (forge, anvil,
# crucible, prompt, sample data) is generated per specialist.
#
# Usage:
#   ./new_guild.sh <guild-name> <domain> [specialist ...]
#
# Examples:
#   ./new_guild.sh guild-sql sql sql_writer sql_optimizer sql_explainer
#   ./new_guild.sh guild-rust rust            # default specialist: rust_specialist
#
# Environment:
#   OUT_DIR   Destination directory (default: ./<guild-name>).
#
# The script is POSIX sh and makes no in-place edits to the template.
set -eu

usage() {
	cat <<'USAGE'
Usage: ./new_guild.sh <guild-name> <domain> [specialist ...]

  <guild-name>   Repository/guild name, e.g. guild-sql
  <domain>       Short domain id, e.g. sql (used for the directory + routing)
  [specialist]   One or more specialist ids; defaults to "<domain>_specialist"

Env: OUT_DIR overrides the destination directory (default ./<guild-name>).
USAGE
}

case "${1:-}" in
-h | --help)
	usage
	exit 0
	;;
esac

if [ "$#" -lt 2 ]; then
	echo "error: need at least <guild-name> and <domain>" >&2
	usage >&2
	exit 2
fi

GUILD_NAME=$1
DOMAIN=$2
shift 2
if [ "$#" -eq 0 ]; then
	set -- "${DOMAIN}_specialist"
fi
FIRST_SPECIALIST=$1

# Locate the skeleton relative to this script so it works from any CWD.
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SKELETON="$SCRIPT_DIR/skeleton"
if [ ! -d "$SKELETON" ]; then
	echo "error: skeleton not found at $SKELETON" >&2
	exit 1
fi

OUT_DIR=${OUT_DIR:-"./$GUILD_NAME"}
if [ -e "$OUT_DIR" ]; then
	echo "error: $OUT_DIR already exists; refusing to overwrite" >&2
	exit 1
fi

echo "Scaffolding $GUILD_NAME (domain: $DOMAIN) into $OUT_DIR"
echo "Specialists: $*"

# 1. Copy the skeleton, then rename the {{DOMAIN}} directory to the real domain.
mkdir -p "$OUT_DIR"
cp -R "$SKELETON/." "$OUT_DIR/"
mv "$OUT_DIR/{{DOMAIN}}" "$OUT_DIR/$DOMAIN"
cp "$SCRIPT_DIR/LICENSE" "$OUT_DIR/LICENSE" 2>/dev/null || true

DOM_DIR="$OUT_DIR/$DOMAIN"

# 2. Expand each {{SPECIALIST}}.* template into one file per specialist.
find "$DOM_DIR" -type f -name '{{SPECIALIST}}.*' | while IFS= read -r tmpl; do
	dir=$(dirname "$tmpl")
	ext=${tmpl##*.}
	for s in "$@"; do
		out="$dir/$s.$ext"
		sed "s|{{SPECIALIST}}|$s|g" "$tmpl" >"$out"
	done
	rm -f "$tmpl"
done

# 3. Substitute the remaining global tokens in every generated file. Any
#    {{SPECIALIST}} left in shared files (guild.yaml, run_tests.sh) resolves to
#    the first specialist.
find "$OUT_DIR" -type f | while IFS= read -r f; do
	sed \
		-e "s|{{GUILD_NAME}}|$GUILD_NAME|g" \
		-e "s|{{DOMAIN}}|$DOMAIN|g" \
		-e "s|{{SPECIALIST}}|$FIRST_SPECIALIST|g" \
		"$f" >"$f.tmp" && mv "$f.tmp" "$f"
done

# 4. Keep the eval runner executable.
if [ -f "$DOM_DIR/tools/run_tests.sh" ]; then
	chmod +x "$DOM_DIR/tools/run_tests.sh"
fi

echo "Done. Next steps:"
echo "  1. cd $OUT_DIR && edit $DOMAIN/guild.yaml (tasks, keywords, briefs)"
echo "  2. Fill the forge query + process settings in $DOMAIN/forge/*.yaml"
echo "  3. Register matching teacher role(s) in forge/src/core/instruction_gen.py"
echo "  4. Register the specialists in brain/configs/guilds.yaml"
