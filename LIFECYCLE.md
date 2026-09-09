# colormath skills lifecycle

The law for how this repo versions, releases, and reaches the people using it.

It is deliberately short, and it is short because of one fact that separates
this repo from [ColorMath/ci](https://github.com/ColorMath/ci), which the
skills were extracted from:

> **Nothing pins this repo.** A consumer's `.claude/settings.json` names the
> marketplace and nothing else — no ref, no tag, no version. Claude Code tracks
> the default branch and auto-updates.

So **the merge is the release**. By the time you cut a version, every install
already has the content; the next `/plugin` update just relabels it. Everything
below follows from that.

Compare ColorMath/ci, where a release is a contract: consumers pin exact tags,
an upgrade arrives as a dedicated PR, and a MAJOR is defined by what can break
without the consumer editing anything. None of that machinery applies here, and
importing it would be theatre.

## Versioning

One SemVer tag stream (`vX.Y.Z`), one CHANGELOG, continuing the stream the
skills were released under while they lived in ColorMath/ci — the extraction
started at **v4.2.0**, the version after ci's `v4.1.0`. Continuity is worth more
than a tidy `v1.0.0`: `/plugin` had been reporting 4.x on every install for
months, and restarting the numbers would have looked like a downgrade to every
one of them.

The version is a **label, not a resolvable ref**. Nobody fetches `v4.2.0`; they
read it in `/plugin` and look it up in `CHANGELOG.md` to find out what changed
under them. That is the whole job, and it is why the numbers still have to mean
something:

- **MAJOR** — a skill is removed or renamed, or one changes what it does
  enough that a person's muscle memory is now wrong. `/colormath:ship` no
  longer merging would be MAJOR.
- **MINOR** — a new skill, or a new step or capability in an existing one.
- **PATCH** — wording, ordering, a corrected instruction, a fixed reference.

There is no deprecation window and no opt-in period, because there is no
version for anyone to sit on: the change is live on merge. If a skill's
behaviour needs to change in a way people should be warned about, the warning
goes in the skill's own output, not in a release channel.

## Releasing

1. Land the change on `main` via PR. **This is the moment it ships** — write
   the changelog entry under `## Unreleased` in the same PR, while you still
   remember why. Never stamp a version by hand.
2. Cut it: run the **Release** workflow with the version, or locally
   `./release/cut.sh vX.Y.Z` (`--dry-run` first to see the diff). That stamps
   `plugin/.claude-plugin/plugin.json`, dates the changelog section, commits,
   creates an annotated tag, pushes both atomically, and publishes the GitHub
   Release.

There is no step 3. No canary, no consumer bump PRs, no soak — the release did
not move any code to anybody.

Cut a release when the accumulated changelog is worth a person reading, not on
a schedule. A batch of merges under one version is fine and normal; what is not
fine is `main` sitting for weeks with an `## Unreleased` section long enough
that nobody can tell which entry describes the behaviour they are looking at.

### The invariant

> On `main`, at every commit: the version in `plugin.json` agrees with the
> newest released section in `CHANGELOG.md`, equals the newest tag reachable
> from `HEAD`, and that tag exists.

Weaker consequences than ColorMath/ci's version of it — a broken stamp here
404s nothing — but the load-bearing half is the same: **the stamp equals the
newest reachable tag, and that tag exists.** It is what makes the label
answerable. Somebody reads `4.2.0` in `/plugin`, opens `v4.2.0` in the
changelog, and gets a true description of the code they are running. A stamp
naming a tag that does not exist gives them a version they cannot look up,
which is worse than no version at all.

`release/verify.sh` is the oracle, and it runs as a blocking check on every PR.
That is safe for the reason it is safe upstream: stamps move only in the
release commit, which is tagged with the version it stamps in the same atomic
push, so a PR that edits no version string inherits main's consistent state and
passes unconditionally.

`release/check-manifests.sh` runs alongside it, and matters more than it looks.
Claude Code fails **quietly** on a malformed manifest — the plugin simply does
not appear — and with no pinning between here and an install, a bad merge
reaches everyone before anyone notices. Those two jobs are the only thing
standing between a bad merge and that.

### When a release goes wrong

Re-running is always safe. `cut.sh` refuses to start from an inconsistent tree,
rolls back its own commit and tag if the atomic push is rejected, and resumes at
the publish step if the tag landed but the GitHub Release did not.

**Never move or delete a published tag.** If a release is wrong, burn the
version: cut the next one and edit the bad Release's body to lead with
**WITHDRAWN — use vX.Y.Z+1**. That costs one integer and stays honest.

A bad *skill* is a different emergency, and a faster one — it is already live.
Fix it and merge; the fix propagates on the next auto-update without anyone
cutting anything. The release afterwards is bookkeeping.

Tags at and below `v4.1.0` were cut in ColorMath/ci and are not reachable from
this repo's history at all — the extraction is a fresh single commit. Their
changelog entries live upstream. `verify.sh --audit-all` therefore starts at
`v4.2.0`, and that is correct, not a truncated table.

## Testing

There is no gate suite here and nothing to run locally but the two release
scripts, which CI runs on every PR:

```
./release/verify.sh            the version invariant above
./release/check-manifests.sh   both manifests parse and describe what is on disk
```

The skills themselves are prose instructions to an agent, and the honest test is
running one against a real repo and reading what it did. `skill-creator` evals
are the closest thing to an automated check; their artifacts are gitignored
(`plugin/skills/*/evals/`, `plugin/skills/qa-workspace/`) because they are full
of fixtures from whichever consumer repo the eval ran against — a record of one
run, not something this repo ships.
