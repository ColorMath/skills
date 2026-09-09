# colormath skills

The [Claude Code](https://code.claude.com) skills for repos built on the
colormath shared infrastructure — a plugin marketplace holding one plugin,
`colormath`, with seven skills that take work from a one-line ticket to a merged
PR.

The gates these skills key on live in
[ColorMath/ci](https://github.com/ColorMath/ci), which is where these skills
lived until v4.2.0. See [Why this is a separate repo](#why-this-is-a-separate-repo).

## Install

```
/plugin marketplace add ColorMath/skills
/plugin install colormath@colormath
```

Or have a repo offer it to everyone who opens it, via `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "colormath": {
      "source": { "source": "github", "repo": "ColorMath/skills" }
    }
  },
  "enabledPlugins": {
    "colormath@colormath": true
  }
}
```

**Coming from `ColorMath/ci`?** Change that one `repo` line. The plugin's name
is unchanged, so every `/colormath:<skill>` command keeps working and
`enabledPlugins` stays as it is.

**There is no version to pin, and that is deliberate.** Claude Code tracks this
repo's default branch, so a merge here reaches every install on its next
auto-update. The version in `/plugin` is a label you can look up in
[CHANGELOG.md](CHANGELOG.md), not something anyone resolves to fetch. See
[LIFECYCLE.md](LIFECYCLE.md).

## The skills

Each one's behaviour, prerequisites and contract dependencies are documented in
[plugin/README.md](plugin/README.md). In rough order of a piece of work's life:

| Skill | Takes | Does |
|---|---|---|
| `/colormath:refine-initiative` | an initiative key | Designs an initiative before it is built — investigates the architecture and decision records its features land in, interviews until the picture is complete, rewrites the initiative and its features. Stops short of code-level plans. |
| `/colormath:plan-initiative` | an initiative key | Runs `refine-ticket` over every ticket under it, in build order, injecting each one's place in the sequence and what the earlier plans decided — so the seams line up. |
| `/colormath:refine-ticket` | a ticket key | Grooms a ticket until it can be worked — investigates the code *before* asking anything, then writes back a standalone description, a file-anchored implementation plan, and an executable QA plan. |
| `/colormath:implement-ticket` | a ticket key | Builds a groomed ticket — checks the plan still matches the code, builds at the layer it names, executes the ticket's QA plan against the running stack, hands off to `ship`. |
| `/colormath:bugfix` | a bug report | Turns a specific report into a merged fix — reproduces it before touching code, fixes at the layer the invariant belongs to, remediates data the bug already corrupted, hands off to `ship`. |
| `/colormath:qa` | a focus area | QAs it against the running stack across security, correctness and accessibility catalogs, reproduces every finding, hands the fixes to `ship`. |
| `/colormath:ship` | the current branch | Opens the PR, watches the gates, reads the review, executes the ticket's QA plan, fixes every finding it can, then decides once: auto-merge when genuinely clean, or hold and explain. |

`refine-ticket`, `refine-initiative`, `plan-initiative` and `implement-ticket`
need the [Abacus](https://github.com/ColorMath/abacus) MCP server connected —
the plugin's one tracker dependency.

## Why this is a separate repo

The skills shipped from ColorMath/ci until v4.1.0. They were split out because
the two halves **propagate in opposite directions**, and one tag stream was
serving both:

|  | ColorMath/ci (gates) | ColorMath/skills |
|---|---|---|
| How a consumer names it | an exact tag: `uses: ColorMath/ci/...@v4.1.0` | a marketplace, no ref |
| How a change arrives | a dedicated PR the consumer merges | automatically, on next `/plugin` update |
| What a release is | a contract — a MAJOR is anything that can turn green CI red | a label on content already shipped |
| What a rollout is | a canary chain of bump PRs across four repos | nothing; the merge was the rollout |

Under one stream, a wording fix in a skill asked four repos to take a gate
release they did not need — and a genuinely urgent skill fix had to wait behind
whatever was unfinished in the gates.

The split changed no skill. It also removed the only CI that ever looked at this
content, which is what [`release/check-manifests.sh`](release/check-manifests.sh)
replaces: Claude Code fails *quietly* on a malformed manifest — the plugin
simply does not appear — and with nothing pinned between here and an install,
a bad merge would reach everyone before anyone noticed.

## Layout

```
.claude-plugin/marketplace.json     the marketplace: one plugin, sourced from ./plugin
plugin/
  .claude-plugin/plugin.json        the plugin manifest — the one versioned stamp site
  README.md                         what each skill does, in full
  skills/<name>/SKILL.md            one directory per skill; the directory name is the command
release/                            cut, stamp, verify, publish — see LIFECYCLE.md
CHANGELOG.md                        what changed, per version
LIFECYCLE.md                        how this repo versions, releases and propagates
```

## Adding a skill

Add `plugin/skills/<name>/SKILL.md` with frontmatter (`name`, `description`,
optional `argument-hint` / `allowed-tools` / `model`); the directory name is the
command name. Document it in [plugin/README.md](plugin/README.md), keep it
consumer-agnostic (no product names, no hardcoded default branch), and note in
the changelog which contract surfaces it depends on — a rename of any of them
must ship with the skill update in the same release.

Remember that merging is what ships it.
