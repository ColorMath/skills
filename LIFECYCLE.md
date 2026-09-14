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

CI runs two things on every PR, and both have a local mirror:

```
./release/verify.sh            the version invariant above
./release/check-manifests.sh   both manifests parse and describe what is on disk
```

Neither looks at behaviour. **The behavioural tests are the eval suites under
`plugin/evals/`** — one directory per skill, each a set of cases that run the
skill against a scaffolded fake repo with the MCP server mocked, and grade what
it did:

```
claude plugin eval ./plugin --eval-dir evals/just-do-it  --scaffold --trust-plugin --threshold 0.8
claude plugin eval ./plugin --eval-dir evals/assess-risk --scaffold --trust-plugin --threshold 0.8
```

**The shape of that command is not obvious and getting it wrong wastes a run.**
The target is the plugin directory, so `--eval-dir` is read *relative to it* —
`evals/assess-risk`, not `plugin/evals/assess-risk`. `--scaffold` is off by
default and without it every case runs against an empty workspace, which fails
in a way that looks like a skill regression; `--trust-plugin` skips the
first-run trust prompt.

**They are an author's pre-flight, not a gate.** A run costs model calls, so CI
does not do it; run the suite for the skill you edited before opening the PR,
and say in the PR what it scored.

**`--ablation` proves nothing about these suites, and the number it prints is
worth less than it looks.** It re-runs each case with the skill removed, which
in general is how you tell a case that measures the skill from one that measures
the model's defaults. But every case here invokes its skill as a **slash
command** (`prompt: "/colormath:assess-risk CM-00301"`), and removing the skill
removes the command: the run ends at `turns: 0` with the last message `Unknown
command: /colormath:assess-risk`. The suite then scores the model's silence.
`assess-risk` measured a mean Δ of +0.76 that way and it means only that the
command existed in one arm and not the other. Read the without-arm's `turns`
before quoting a Δ; if it is 0, there is no comparison in it.

So **the evidence that a case measures the skill has to be made by hand, and it
is worth more than the ablation would have been**: delete the paragraph of the
skill a grader is supposed to be sensitive to, re-run that case, and watch the
specific grader drop — then restore it. A grader that does not move when its
subject is deleted is not measuring what its name says. Do it per grader rather
than per case, because a case's score is a mean and a mean can absorb one
grader going quiet.

Two things that only became clear from doing it. **Give a falsification several
runs, and read how many judges dissented rather than only how many runs
failed** - one failing run out of two is a signal and not a result. And
**expect a grader that watches for an act to be sharp, and one that judges a
quality to be soft.** `assess-risk` falsified both kinds: deleting the rule
against writing the description failed `no-write` six votes out of six across
two runs, because "did this call appear" has one answer; deleting the paragraph
that sets the rationale bar failed `rationales-are-specific` in one run of five,
because "is this sentence specific enough" is a matter of degree and three
judges split on it. Both are worth keeping. Only the first kind can be read as
a gate, and a soft grader's weakness belongs in the PR rather than in a
deterministic replacement that passes on any rationale containing a slash.

**`mocks/<server>/_tools.json` is a second allowlist, and it is the stricter
one.** A skill's `allowed-tools` cannot let a run make a call the mocked server
does not serve: the first attempt at the falsification above added
`update_ticket` to the allowlist, instructed the skill to use it, and scored a
clean pass because the run tried, found no such tool, and said so in its report.
That is fail-safe, and it also means **a grader asserting that some MCP write
never happens has never been in a position to see one.** When you want to
falsify a don't-call-this grader, add the tool to the fixture as well - and when
you write one, know that its live teeth are the writes the fixture actually
serves plus the file and shell writes nothing else constrains.

Each case directory holds `case.yaml`, a `graders/` directory, a `mocks/`
directory and a copy of the suite's `_shared/scaffold.sh`. Three things about
mocks are easy to get wrong and expensive to discover:

- `mocks/<server>/_tools.json` is a saved `tools/list` response, and it is what
  gives the model the **real** tool schema. Without it the runner serves every
  tool with a permissive schema and no description, so a skill specified to read
  something out of a tool's own `enum` — `assess-risk` reads the risk rubric
  that way — is graded against a vocabulary that does not exist.
- **A root-level `anyOf` in a mocked tool's `inputSchema` makes the child drop
  that tool**, and the run then dies in the pre-flight with `mocked tools not
  offered by the child: <name>`. Abacus really does serve one on `get_ticket`
  (`ticket_id` or `key`), and an ordinary Claude Code session accepts it — this
  is a trap in the eval child, not a malformed schema. Strip it from the mock
  and keep the rest; `additionalProperties: false` is fine.
- The scaffold copy in each case must stay byte-identical to `_shared/`. It is
  duplicated rather than referenced because the harness copies one script per
  case; `diff` them when you touch it.

And one thing about **graders** that is worse than any of them, because it
costs a full suite run rather than a pre-flight:

> **A grader reads one thing, and by default that thing is the agent's closing
> message.** `focus:` on an `llm` grader and `target:` on a `regex` one both
> default to `last_message`. The other values are `trace` (every tool call the
> run made, as JSON lines), `files` (the paths the run *created*, never their
> contents and never a file it merely edited) and `mock_calls` (each mocked
> call with its arguments and its reply).

So a rubric that says "score 1 only if the agent called `set_ticket_risk` once
per criterion" and leaves the focus alone is asking a judge to rule on evidence
it was never shown, and it votes on the agent's prose instead. That is not a
grader that is merely weak — it is one whose result is noise, and noise reads
exactly like a skill regression. It cost this suite a $2.00 red run in which
every case had behaved correctly. **Any grader that reasons about what the run
did takes `trace` or `mock_calls`; `last_message` is for grading the report.**

Two corollaries worth having written down:

- **Prefer a deterministic grader wherever the question is countable.** `type:
  tool_used` with `tool`, `min` and `max` answers "exactly five calls" and
  "never called `add_comment`" without a judge at all. The name must be the
  **full** tool name as the trace records it — `mcp__abacus__set_ticket_risk`,
  not `set_ticket_risk`. For a must-not-call check, set `min: 0`, `max: 0` and
  `arm: both`: omitting `min` leaves it at 1, and omitting `arm` on `tool:
  Skill` makes the grader display-only under ablation.
- **A rubric that grades a refusal must let a run that did nothing pass.** An
  `llm` grader worded as "score 1 if the only things it wrote were ratings"
  gives a correct refusal — which wrote nothing at all — no way to score, and
  the judge resolves the gap against you.
- **A mock's reply is a stand-in, and a rubric must say so.** `mock_calls`
  renders each call as an `input` and an `output`, and the `output` is whatever
  fixed text the fixture holds — the same for every call, whatever was sent. A
  fixture that looks like a receipt (`"criterion": "blast_radius", "level":
  "medium"`) therefore contradicts its own input on four calls out of five, and
  a judge asked "was each criterion rated exactly once" reads the contradiction
  as the failure it was told to look for. Two halves to the fix, and both are
  needed: make the reply an acknowledgement that plainly echoes nothing, and
  tell the rubric to rule on the `input`. This cost a red run in which every
  case had behaved correctly, and it failed only three cases out of five — with
  a byte-identical fixture — because which half a judge reads is luck.
- **One rubric per behaviour, even when three cases look alike.** Three refusal
  cases shared one `declines.md`, and the skill asks something different of
  each: the initiative case must decline *and offer to assess the children*,
  the task case must decline and stop, the missing-tool case must say why
  nothing was recorded. A rubric general enough to cover all three scored the
  mandatory offer as hedging and failed two runs that had followed the skill
  exactly. A shared grader that has to be worded vaguely is two graders.
- **A negative example phrased like real output turns a rubric into a substring
  match.** A rubric was tightened with a worked pair -- "No external APIs are
  involved" scores 0, the sentence naming what was read scores 1 -- and the next
  run failed a rationale that named three files and said which imports it had
  checked, because it *opened* with that clause before going on to the evidence.
  The judge had been handed something to pattern-match and stopped reading. Write
  the **rule** ("judge the whole sentence: does it say what was looked at") and
  keep the illustration far enough from the wording real runs produce that it
  cannot be matched instead of applied.
- **A fixture's own content is rendered in the same focus the calls are.**
  `mock_calls` shows `get_ticket`'s reply as well as the writes, so a case whose
  fixture carries three pre-existing risk ratings shows those three criteria
  twice: once inside what the run read, once as what the run sent. A rubric
  scoring 0 "if one was rated twice" then fails a correct run roughly one time in
  three, depending on how closely a judge reads the earlier call -- and the
  deterministic count grader beside it passes on the same evidence. Two things
  follow. Say in the rubric which calls count. And when a countable grader and a
  judge disagree about one run, **the countable one is right** and the rubric is
  what to read next; that heuristic has been correct every time it has come up
  here.

**A pre-flight failure costs $0.00 and no model calls**, which is what makes
fixture bugs cheap to bisect: copy one case into a throwaway suite, cut
`max_turns` to 1, and change one thing at a time until the pre-flight passes.

A run writes to `plugin/evals/<suite>/results/`, which is gitignored: the suite
is source, one run of it is not. So is `.colormath/`, the agent scratch
workspace, and the older `skill-creator` eval artifacts
(`plugin/skills/*/evals/`, `plugin/skills/qa-workspace/`), which were full of
fixtures from whichever consumer repo they ran against.

None of that replaces running a skill against a real repository and reading what
it did. The suites catch the regressions a rewrite introduces; they do not tell
you the skill is worth having.
