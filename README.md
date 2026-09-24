# colormath skills

The [Claude Code](https://code.claude.com) skills for repos built on the
colormath shared infrastructure — a plugin marketplace holding one plugin,
`colormath`, with nine skills that take work from a one-line ticket to a merged
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
| `/colormath:gather-requirements` | a ticket or initiative key | Settles what is being asked for — investigates enough to ask good questions, interviews until the picture is complete, then writes back a standalone description, and on an initiative its feature definitions too. Writes no plans. |
| `/colormath:plan-initiative` | an initiative key | Runs `plan-ticket` over every ticket under it, in build order, injecting each one's place in the sequence and what the earlier plans decided — so the seams line up. |
| `/colormath:plan-ticket` | a ticket key | Plans a gathered ticket until it can be worked — investigates the code at file-and-line level, then writes back a file-anchored implementation plan and an executable QA plan, and runs `assess-risk` over the result. Writes no description. |
| `/colormath:assess-risk` | a ticket key | Rates a planned ticket against the engineering-risk rubric the tracker declares — reads the criteria out of the tool, goes and looks at the code each one asks about, then writes one level and one specific rationale per criterion. Advisory: it refuses nothing and moves nothing. Usually reached through another skill rather than typed. |
| `/colormath:implement-ticket` | a ticket key | Builds a groomed ticket — checks the plan still matches the code, builds at the layer it names, executes the ticket's QA plan against the running stack, re-assesses the risk if the build changed the shape of the work, hands off to `ship`. |
| `/colormath:just-do-it` | a ticket key | The fast path, for work already thought through — checks the ticket is genuinely small, assesses its risk, then builds and ships it in one session instead of three skills. Hands back rather than guessing when it turns out not to be. |
| `/colormath:bugfix` | a bug report | Turns a specific report into a merged fix — reproduces it before touching code, fixes at the layer the invariant belongs to, remediates data the bug already corrupted, re-assesses the risk if the fix outgrew the bug, hands off to `ship`. |
| `/colormath:qa` | a focus area | QAs it against the running stack across security, correctness and accessibility catalogs, reproduces every finding, hands the fixes to `ship`. |
| `/colormath:ship` | the current branch | Opens the PR, watches the gates, reads the review, executes the ticket's QA plan, fixes every finding it can, then decides once: auto-merge when genuinely clean, or hold and explain. |

Every skill that takes a ticket key — `gather-requirements`, `plan-ticket`,
`plan-initiative`, `assess-risk`, `implement-ticket` and `just-do-it` — needs
the [Abacus](https://github.com/ColorMath/abacus) MCP server connected, the
plugin's one tracker dependency. `assess-risk` wants a recent one: it writes
through `set_ticket_risk`, and an Abacus without that tool is one it will
decline to work against rather than file the assessment somewhere else.

**Risk is assessed by the skills, not left to somebody remembering.**
`assess-risk` is the one skill you are not expected to type. `plan-ticket` runs
it every time, right after its code pass — the rubric asks about blast radius,
migrations and authorization surface, which is what that pass just spent its time
on, so running it anywhere else means paying for the same reading twice.
`just-do-it` runs it *before* building, because that path has no plan and no
groomed QA plan behind it. `implement-ticket` and `bugfix` re-run it only when the
work changed shape — a migration nobody planned, a fix that landed deeper than the
report suggested — since re-rating for its own sake writes a measurement nobody
can delete. `plan-initiative` adds no call of its own and inherits one per child.

Nothing is ever refused over a rating, by a person or by a skill. A rating tells
whoever picks the work up what they are taking on; it is not a gate, and a high
one is not a reason to hold, descope or re-plan.

**Grooming is two skills, and the split is the contract.**
`gather-requirements` owns `description` (and an initiative's features);
`plan-ticket` owns `plan` and `qa_plan`. Neither writes the other's fields, so
the requirements a plan is built on were settled and read by somebody before
the plan existed. Abacus's project schema names them per column for the same
reason: `gather-requirements` moves work into **Designing**, `plan-ticket` into
**Ready for Implementation**.

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
  evals/<skill>/                    one eval suite per skill — see LIFECYCLE.md#testing
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
