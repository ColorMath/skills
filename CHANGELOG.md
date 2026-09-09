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

## v5.1.0 — 2026-09-09

MINOR. Two new steps in existing skills, and both are about a ticket telling
the truth about itself while the work is happening rather than afterwards.

### Changed

- **`implement-ticket` and `bugfix` claim the ticket when they start.** Both
  moved it into Implementing at the very end of their runs, immediately before
  handing off to `ship`. That column is a claim in the present tense — somebody
  is on this — and a move made at the end was never true while it was true: the
  ticket sat where it was filed through the whole of the reading, reproducing,
  building and QA, which is exactly the window in which a second person might
  pick the same work up, and then flickered through Implementing on its way to
  ship. A lane no ticket is ever observed in is not doing anything.

  The move is now `implement-ticket`'s step 2, right after the readiness gate
  and before it reads a line of the code, and `bugfix`'s step 2, once it knows
  what it was handed and before it brings a stack up. Each skill's gate is what
  makes going first safe: by then the ticket exists, can be worked, and is going
  to be.

  Both keep the ticket's original `swimlane_id` and **move it back** on the
  endings that are not a fix — `implement-ticket` when the plan no longer
  describes the code and the ticket goes back to `plan-ticket` or
  `gather-requirements`, `bugfix` when it cannot reproduce the defect and stops.
  Those are the honest outcomes, and a ticket parked in Implementing with nobody
  on it is a worse lie than the one moving early corrects.

  `ship` is unchanged and needed no change: it matches its own `skill` in
  `exit_commands` and moves the ticket on from whatever column it finds it in,
  which is the same column either caller left it in — just claimed earlier. The
  ordering v5.0.0 made load-bearing still holds.

### Added

- **Every skill that has a ticket records that it ran.** On finishing, each
  calls `record_metric` with `skill_invoked` and its own bare name as the
  subject, so a ticket carries a count of the work done *against* it — which
  Abacus cannot observe for itself, since nothing outside a skill's own run
  knows it started ([abacus#101](https://github.com/ColorMath/abacus/pull/101)).

  The counts worth having are the ones nobody wants. A ticket gathered four
  times is a ticket whose requirements will not settle; a bug fixed twice is a
  bug whose cause was never found. From the outside the fourth run looks exactly
  like the first.

  Recorded **once, at the end, and only on work actually done** — an interrupted
  run and a hand-back both record nothing, because a run that did not happen
  must not leave a row saying it did. `ship` records on a **held** PR as well as
  a merged one: ship ran either way. `plan-initiative` records only itself; each
  `plan-ticket` it invokes records its own run against its own child. Rows are
  append-only and nobody can edit or delete one, so a wrong subject is
  permanent.

  A metric and the board move above point opposite ways in time, and are not in
  tension: a column is a claim about what is happening now, so it is only useful
  said early, while a metric is a record of what happened, which cannot be
  written until it has.

  **`/colormath:qa` records nothing, deliberately.** It takes a focus area, not
  a ticket, and the only way to give `record_metric` an id would be to pick a
  ticket the round happened to touch — a measurement filed against work it was
  not a measurement of. The skill says so, so the gap is not mistaken for an
  omission.

### Fixed

- **`cut.sh` no longer reports a still-running CI as a failed one.** It read the
  CI run's `conclusion` and nothing else, and `gh` reports an unfinished run's
  conclusion as an **empty string** rather than as null — so the `// "none"`
  fallback never fired, because jq's `//` substitutes only null and false and
  `""` is truthy. A release dispatched while CI was still going therefore died
  with *"the CI run for <sha> concluded '' — fix main before releasing"*, which
  sent the releaser to look at a failure that did not exist. It now reads
  `status` first — already fetched and previously unused — and says *"CI for
  <sha> is still in_progress — wait for it to finish, then rerun"*.

- **`cut.sh` refuses to cut an empty `## Unreleased` section.** `notes.sh`
  already declines to write empty release notes, but it does not run until after
  the release commit exists, so the failure left a stray local commit to clean
  up. It is a precondition, and is now checked with the tree still untouched.
  The check belongs there rather than in `verify.sh`, which runs on every PR and
  would fail main for the whole legitimate window between a cut and the next
  merge.

- **The v5.0.0 changelog section describes v5.0.0 again.** The two entries above
  were written under `## Unreleased` on branches cut before v5.0.0 was, and the
  release renamed that heading while they were in flight; git merged the rename
  and the bodies without a conflict, so both entries landed inside the released
  section. The published `v5.0.0` tag and GitHub Release never contained them —
  only the file on `main` had drifted.

## v5.0.0 — 2026-09-09

MAJOR. **Grooming splits into two skills.** `/colormath:refine-ticket` and
`/colormath:refine-initiative` are gone, replaced by
`/colormath:gather-requirements` and `/colormath:plan-ticket`. Skill renames
are MAJOR because nothing pins this repo — a merge here reaches every install
on its next `/plugin` update, and anything naming the old commands (a runbook,
a board column, a bookmark) stops resolving at that moment.

### Removed

- **`/colormath:refine-ticket`** — its work is now done by two skills. The
  description half is `gather-requirements`; the plan half is `plan-ticket`.
- **`/colormath:refine-initiative`** — folded whole into
  `gather-requirements`, which branches on ticket `type` and writes feature
  definitions when it is handed an initiative.

### Added

- **`/colormath:gather-requirements`** — settles *what is being asked for*, for
  a ticket **or** an initiative. Reads it, investigates the code and the
  decision records, interviews until the picture is complete, then writes back
  a description that stands on its own — plus, on an initiative, its feature
  definitions. It **never writes `plan` or `qa_plan`**.

  It is also, for the first time, the *complete* grooming path for a **task**.
  `refine-ticket` handled a task badly: it was built to produce plans, and
  Abacus refuses to write one on a task at all.

- **`/colormath:plan-ticket`** — settles *how it gets built*. Takes a ticket
  whose requirements are already gathered, investigates the code at
  file-and-line level, settles the few implementation forks the requirements
  left open, then writes back a file-anchored implementation plan and an
  executable QA plan. It **never writes `description`**; on an initiative or a
  task it stops and says which skill is the right one.

### Changed

- **The skills move the ticket now.** `gather-requirements`, `plan-ticket`,
  `implement-ticket`, `bugfix` and `ship` each move the ticket into the next
  board column, so the board reflects what has actually happened instead of
  waiting for somebody to drag a card.

  **They ask the board where to move it.** `get_board` returns the swimlanes in
  board order, each carrying `exit_commands` — the commands that move work *on
  from* that column. Every entry says its `skill`, the whole `command` line, and
  **`leads_to`, the id of the swimlane that command moves the ticket into**. A
  skill matches its own bare name against `skill` and hands `leads_to` straight
  to `move_ticket`.

  Nothing counts lanes, and that is deliberate: derived as "the swimlane after
  the one naming me", the destination has exactly one wrong answer available —
  the lane you matched — and taking it sends every ticket one column *backwards*
  with nothing in the system to notice. No skill matches a column title either,
  so a renamed column keeps working and a board on a different schema is simply
  left alone.

  This reverses an explicit instruction in `implement-ticket` and `bugfix` not
  to move tickets, and the reason it can be reversed is the interesting half:
  that rule existed because lane meaning was per board and free text, so one
  team's "In Review" was another's "Staging". Abacus columns come from a schema
  now and declare which skill leads into them, so there is nothing left to
  guess.

  **`ship` moves it too, and the order is load-bearing.** `implement-ticket`
  and `bugfix` *invoke* `/colormath:ship`, so both now move the ticket **before**
  the handoff rather than after it: their move says the code is written, and
  taking it through the PR pipeline is ship's move to make, one column further
  on. Left the other way round, ship would move the ticket out of a column
  `implement-ticket` had not yet left, and `implement-ticket` would then move it
  back. Ship moves whether the PR merged **or is held** — held is the ordinary
  outcome on a repo with no review workflow, and a move that happened only on a
  merge would never happen there at all.

  A skill moves the ticket **only on success**, and never when the ticket is
  still in the backlog — a lane comes from a release or an initiative, and
  Abacus refuses the move with *"Plan this ticket for a release, or file it
  under an initiative, before giving it a status."* Both cases are reported
  rather than retried. `plan-initiative` moves nothing itself; the `plan-ticket`
  calls it makes each move their own ticket.

- **The split is the contract.** `gather-requirements` owns `description` (and
  an initiative's features); `plan-ticket` owns `plan` and `qa_plan`. Neither
  writes the other's fields, so the requirements a plan is built on were
  settled and read by somebody before the plan existed. `plan-ticket` hands a
  thinly-described ticket back rather than inventing the missing half.

- **`/colormath:plan-initiative`** now loops `plan-ticket` rather than
  `refine-ticket`, points a `designing` initiative at `gather-requirements`,
  and flags children whose descriptions are too thin to plan against before
  the run starts rather than seven tickets in.

- **`/colormath:implement-ticket`** sends a ticket with no plan back to
  `plan-ticket`, and a ticket that needs several rounds of questions back to
  `gather-requirements`.

- **`/colormath:ship`** drafts a missing QA plan "the way `plan-ticket` would".

### Upgrading

Replace the old commands wherever they are written down:

| Old | New |
|---|---|
| `/colormath:refine-ticket <key>` on an ungroomed ticket | `/colormath:gather-requirements <key>`, then `/colormath:plan-ticket <key>` |
| `/colormath:refine-ticket <key>` on a ticket that just needs plans | `/colormath:plan-ticket <key>` |
| `/colormath:refine-initiative <key>` | `/colormath:gather-requirements <key>` |
| `/colormath:refine-ticket <key>` on a **task** | `/colormath:gather-requirements <key>` — and that is the whole of it |

[Abacus](https://github.com/ColorMath/abacus) names every one of these on its
Product board schema, and that half has already shipped:

```
To Do                     →gather-requirements
Designing                 →plan-ticket
Ready for Implementation  →implement-ticket →bugfix
Implementing              →ship
Code Complete             ·qa
Done
```

An arrow is a skill that moves work on; a dot is one run there that moves
nothing. **Implementing is new on that board** — written code is not shipped
code, so `ship` is what crosses into Code Complete. `qa` stays resident: a bug
it finds is a bug, not a lane change. Abacus also prints `plan-ticket <key>` as
the hint on a ticket that is not yet ready.

Nothing here needs Abacus, though. A board whose schema names none of these
skills is left alone, and every skill reports that rather than guessing.

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
