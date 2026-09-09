#!/usr/bin/env bash
#
# The manifests parse, and they describe what is on disk.
#
# Claude Code fails *quietly* on a malformed manifest: the plugin does not
# appear, with no error anyone downstream would see. Combined with this repo
# tracking its default branch rather than a tag, that means a bad merge is live
# for every install on its next auto-update. Hence a check rather than trust.
#
# Deliberately not a schema validator. It asserts the handful of things that
# have actually broken or could break silently, and says why for each.

set -euo pipefail

ROOT="${COLORMATH_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_JSON="$ROOT/plugin/.claude-plugin/plugin.json"

failures=0
fail() {
	echo "FAIL: $*" >&2
	failures=$((failures + 1))
	[ -n "${GITHUB_ACTIONS:-}" ] && echo "::error::$*"
	return 0
}
pass() { echo "ok: $*"; }

for f in "$MARKETPLACE" "$PLUGIN_JSON"; do
	if [ ! -f "$f" ]; then
		fail "${f#"$ROOT"/} is missing"
	elif ! python3 -m json.tool "$f" >/dev/null 2>&1; then
		fail "${f#"$ROOT"/} is not valid JSON"
	else
		pass "${f#"$ROOT"/} parses"
	fi
done
[ "$failures" -eq 0 ] || { echo; echo "$failures check(s) failed." >&2; exit 1; }

# The marketplace's plugin source is a path in this repo, and it must exist.
# A source pointing at nothing installs an empty plugin rather than failing.
source_path=$(python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
plugins = d.get("plugins") or []
print(plugins[0].get("source", "") if len(plugins) == 1 else "")
' "$MARKETPLACE")

if [ -z "$source_path" ]; then
	fail "marketplace.json should declare exactly one plugin with a source"
elif [ ! -d "$ROOT/${source_path#./}" ]; then
	fail "marketplace.json source '$source_path' is not a directory in this repo"
else
	pass "marketplace source '$source_path' exists"
fi

# Every skill directory holds a SKILL.md, and every SKILL.md opens with YAML
# frontmatter carrying a name and a description. Claude Code needs both to list
# the skill; a skill missing either is invisible rather than broken.
#
# qa-workspace is eval scratch, not a skill — it has no SKILL.md by design.
skills_dir="$ROOT/${source_path#./}/skills"
found=0
for d in "$skills_dir"/*/; do
	name=$(basename "$d")
	[ "$name" = "qa-workspace" ] && continue
	found=$((found + 1))
	f="$d/SKILL.md"
	if [ ! -f "$f" ]; then
		fail "skills/$name has no SKILL.md"
		continue
	fi
	head -1 "$f" | grep -q '^---$' || { fail "skills/$name/SKILL.md does not open with '---' frontmatter"; continue; }
	fm=$(awk 'NR>1 && /^---$/{exit} NR>1' "$f")
	grep -qE '^name:[[:space:]]*\S' <<<"$fm" || fail "skills/$name/SKILL.md frontmatter has no name:"
	grep -qE '^description:[[:space:]]*\S' <<<"$fm" || fail "skills/$name/SKILL.md frontmatter has no description:"
done
[ "$found" -gt 0 ] || fail "no skills found under ${skills_dir#"$ROOT"/}"
[ "$failures" -eq 0 ] && pass "$found skills carry name+description frontmatter"

echo
if [ "$failures" -gt 0 ]; then
	echo "$failures check(s) failed." >&2
	exit 1
fi
echo "All manifest checks passed."
