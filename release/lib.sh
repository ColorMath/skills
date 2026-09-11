#!/usr/bin/env bash
#
# Shared helpers for the colormath-skills release scripts. Sourced, never executed.
#
# Everything that knows *where* a version is written down lives here, in the
# read_*/write_* pairs below. Adding a new stamp site means adding one pair and
# one entry in STAMP_SITES — stamp.sh and verify.sh both drive off that list, so
# a new site cannot be stamped-but-unverified or verified-but-unstamped. That
# asymmetry is exactly how plugin.json drifted while it lived in ColorMath/ci:
# it was a stamp site nothing checked.
#
# This repo has exactly **one** machine-read stamp site — plugin.json's version,
# which is the number Claude Code shows in `/plugin`. The other two sites
# (gates.yml's colormath-ref default and Makefile.colormath's COLORMATH_REF)
# stayed behind in ColorMath/ci with the gates they pin. One site makes "the
# sites agree with each other" trivially true, so the load-bearing half of the
# invariant is the rest — that the stamp equals the newest reachable tag, and
# that the tag exists.
#
# Documentation examples are deliberately not stamped; they carry a literal
# "vX.Y.Z" placeholder so there is nothing there to rot.

set -euo pipefail

# Repo root, regardless of where a script was invoked from.
COLORMATH_ROOT="${COLORMATH_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

PLUGIN_JSON="$COLORMATH_ROOT/plugin/.claude-plugin/plugin.json"
CHANGELOG="$COLORMATH_ROOT/CHANGELOG.md"

# The machine-read stamp sites, as "label:reader:writer". stamp.sh runs every
# writer; verify.sh runs every reader and requires them to agree.
STAMP_SITES=(
	"plugin.json version:read_plugin_version:write_plugin_version"
)

die() {
	echo "error: $*" >&2
	exit 1
}

note() { echo "  $*"; }

# --- version helpers --------------------------------------------------------

# Accepts "3.1.0" or "v3.1.0"; always prints the "v" form. Rejects anything
# else, so a typo becomes an error rather than a tag named "v3..1.0".
normalize_version() {
	local v="${1#v}"
	[[ "$v" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "not a SemVer version: $1 (expected X.Y.Z or vX.Y.Z)"
	echo "v$v"
}

# The newest tag reachable from HEAD, by SemVer order.
#
# Deliberately not `git describe --tags --abbrev=0`, which returns the most
# recent tag by *commit distance*. On a history where v2.4.0 and v3.0.0 sit on
# adjacent merges, distance and SemVer can disagree, and the invariant is a
# statement about SemVer.
newest_reachable_tag() {
	git -C "$COLORMATH_ROOT" tag --merged HEAD --sort=-v:refname | head -1
}

# True when $1 sorts strictly above $2 in SemVer order.
version_gt() {
	[ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

tag_exists_locally() { git -C "$COLORMATH_ROOT" rev-parse -q --verify "refs/tags/$1" >/dev/null 2>&1; }

tag_exists_on_origin() { [ -n "$(git -C "$COLORMATH_ROOT" ls-remote --tags origin "refs/tags/$1" 2>/dev/null)" ]; }

# --- stamp site readers -----------------------------------------------------
#
# Each reader prints the version in "vX.Y.Z" form, or nothing if the site could
# not be parsed. Callers treat empty as a hard error — a site that stopped
# matching is a site that silently stopped being stamped.

# plugin.json stores a bare "3.1.0"; print it in "v" form so every reader is
# directly comparable.
read_plugin_version() {
	local raw
	raw=$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*$/\1/p' "$PLUGIN_JSON" | head -1)
	[ -n "$raw" ] && echo "v$raw"
}

# The newest *released* section heading in the changelog, ignoring Unreleased.
read_changelog_latest() {
	sed -n 's/^## \(v[0-9][0-9.]*\) — .*$/\1/p' "$CHANGELOG" | head -1
}

changelog_has_unreleased() { grep -q '^## Unreleased[[:space:]]*$' "$CHANGELOG"; }

# --- stamp site writers -----------------------------------------------------
#
# An anchored pattern, never a global version replace. The changelog names old
# versions on purpose, and every skill is free to cite the release a behaviour
# arrived in; rewriting any of that would be a silent falsification of history.

write_plugin_version() {
	sed -i '' "s|^\([[:space:]]*\"version\"[[:space:]]*:[[:space:]]*\"\)[0-9][0-9.]*\(\"\)|\1${1#v}\2|" "$PLUGIN_JSON"
}
