# Changelog

All notable changes to the colormath skills. Versioning per
[LIFECYCLE.md](LIFECYCLE.md): one SemVer stream, continuing the one these skills
were released under in [ColorMath/ci](https://github.com/ColorMath/ci) up to
`v4.1.0`. **Nothing pins this repo** — Claude Code tracks the default branch, so
the merge is the release and the version is the label you read in `/plugin` and
look up here.

Changes land under `## Unreleased`; `release/cut.sh` renames that heading to the
version being cut and opens a fresh one. The date on a section is the date the
release was cut, and every section is also the body of that version's
[GitHub Release](https://github.com/ColorMath/skills/releases).

Entries for `v4.1.0` and earlier are in
[ColorMath/ci's changelog](https://github.com/ColorMath/ci/blob/main/CHANGELOG.md),
which still covers the gates. This repo's history begins at the extraction.

## Unreleased

## v4.2.0 — 2026-09-08

MINOR. The skills move house. **Nothing about any skill changed** — same seven
skills, same instructions, byte for byte — so no consumer needs to relearn
anything. What changed is the one line naming where they come from.

### Changed

- **The colormath skills now live in `ColorMath/skills`.** They were extracted
  from `ColorMath/ci`, which keeps the gates, the review workflow and the
  vendored consumer files.

  **Every consumer must update one line**, because the marketplace is named by
  repository and that repository is now a different one:

  ```diff
   {
     "extraKnownMarketplaces": {
       "colormath": {
  -      "source": { "source": "github", "repo": "ColorMath/ci" }
  +      "source": { "source": "github", "repo": "ColorMath/skills" }
       }
     },
     "enabledPlugins": { "colormath@colormath": true }
   }
  ```

  The plugin's own name is unchanged, so every `/colormath:<skill>` command
  keeps working and `enabledPlugins` is untouched.

  MINOR rather than MAJOR on the rule in [LIFECYCLE.md](LIFECYCLE.md): no skill
  was removed, renamed, or made to behave differently. The edit above is a
  one-time cutover, and a consumer that has not made it keeps running the last
  copy it fetched rather than breaking.

  **Why split at all.** The two halves propagate in opposite directions and
  always did. Gates are pinned to an exact tag by every consumer: a release is a
  contract, a MAJOR is defined by what can turn green CI red, and a rollout is a
  canary chain of bump PRs. Skills are pinned by nobody: Claude Code tracks the
  default branch, so a merge reaches every install on its next auto-update and
  the version is a human-facing label rather than something resolved to fetch.
  One tag stream was serving both, which meant every skill wording fix asked
  four repos to take a gate release they did not need.

### Removed

- **The gate machinery, from the skills' release path.** `release/lib.sh` had
  three stamp sites — `gates.yml`'s `colormath-ref`, `Makefile.colormath`'s
  `COLORMATH_REF`, and `plugin.json`'s `version` — and here only the last one
  exists. `verify.sh` loses its vendored-copy byte-identity check along with the
  `example/` consumer it compared against, and `backfill-releases.sh`, a one-off
  that walked ci's own tag history, is gone rather than carried.

### Added

- **`release/check-manifests.sh`, and a CI job that runs it.** The split removed
  the only CI that ever looked at this content. Because consumers track the
  default branch, a malformed `plugin.json` or `marketplace.json` reaches every
  install before anyone cuts a release — and Claude Code fails *quietly* on one,
  showing no plugin rather than an error. The check asserts both manifests
  parse, that the marketplace's source resolves to a real directory, and that
  every skill carries `name` and `description` frontmatter.
