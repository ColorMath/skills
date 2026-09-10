# colormath plugin

Claude Code skills for repos built on the colormath (ColorMath/ci) shared
infrastructure. Install via the marketplace at the repo root — see the
[main README](../README.md#install) — then invoke each
skill as `/colormath:<skill>`.

Skills here encode the colormath *contract* — gate check names, comment
markers, make endpoints. That's the test for whether a skill belongs in this
plugin: if it would work in any repo, it goes elsewhere; if it greps for
`gates / *` or `## Thermonuclear Review`, it lives here, so a release that
changes the contract ships the matching skill change in the same diff.

## `/colormath:ship` — PR pipeline end to end

Takes the current branch through the full PR pipeline and stops at a
recommendation:

1. **Open the PR** — pushes the branch, creates the PR (`gh pr create`) with a
   diff-summarizing body; takes an optional PR title as its argument.
2. **Watch the gates** — polls until every `gates / *` check is green; on a
   red gate it reads the failing job's logs, fixes the cause on the branch,
   pushes, and re-watches.
3. **Wait for review** — if the repo calls colormath's review workflow, waits
   for the `review / review` check and reads the `## Thermonuclear Review`
   comment (plus any formal/human reviews and inline comments — full bodies,
   never truncated). Skips this wait, and says so, in repos without the
   review workflow. Distinguishes the three conclusions that look alike from a
   distance: a clean review, a `SKIPPED` one (the workflow's `triage` job found
   only docs/lockfiles to look at — legitimate, and it checks the file list),
   and one that errored before posting (e.g. the workflow-validation guard when
   a PR edits the review caller itself) — reporting the last instead of
   treating silence as a clean review.
4. **QA against the ticket's plan** — resolves the ticket from the branch, PR
   and commits, then reads its `qa_plan` from Abacus and runs it against the
   **running** stack, reusing the `qa` skill's recon + verify discipline and
   driving a browser for UI items when one is reachable (marking them `⚠️`
   unverified when not). If the ticket has no `qa_plan` it **writes one** into
   the field, marked as ship-authored; if the plan is stale it amends it in a
   ticket *comment* rather than editing the groomed field; if there is no ticket
   at all it drafts the plan in the PR. Posts a `## QA Results` comment — and
   mirrors it to the ticket — checking off each item with the evidence it
   observed; `❌` findings feed the fixes in step 5. Never skipped.
5. **Fix every finding — blockers included** — fixes every review finding and
   every `❌` QA finding it can, **without asking**, re-verifying each repro
   against the running stack, and posts the **Addressed / Not changed** response
   comment. It never re-triggers the review — that loop has no exit condition.
   Only findings that genuinely need a human — a
   design decision, or a `CHANGES_REQUESTED` structural call — are deferred.
6. **Restore** — undoes any local state step 4 mutated (rows, files, minted
   credentials, flipped config), and shows you the restored baseline.
7. **Final review — auto-merge or hold** — if no blockers stand *and* QA was
   performed and passed, posts a comment and **auto-merges** the PR
   (`gh pr merge`, honoring the repo's merge convention). If either isn't true —
   a standing blocker, a finding deferred to a human, or QA that failed or
   couldn't run — it posts *why* it held off and stops, leaving the merge to
   you.

Hard rules baked in: it never pushes to the default branch, and it merges
**only** from the gated step-7 final review (both conditions satisfied, with a
PR comment first) — otherwise it holds and explains.

**Prerequisites:**

- An authenticated `gh` CLI with push access to the repo.
- The colormath gates caller (`.github/workflows/gates.yml`) — step 2 keys on
  the `gates / *` check names it produces.
- Optional: the colormath review caller (job named `review`, per the adoption
  docs) — step 3 keys on the `review / review` check and the
  `## Thermonuclear Review` comment marker. Without it, step 7 always holds:
  QA alone does not carry a merge.
- The Abacus MCP server, for step 4's `qa_plan` lookup and write-back. Without
  it the step still runs — ship drafts the plan in the PR — but nothing is read
  from or recorded on the ticket.
- For step 4, a locally runnable stack (run commands + ports in
  `AGENTS.md` / `CLAUDE.md`) and seeded accounts — same prerequisites as
  `/colormath:qa`, whose `references/` it reuses. A browser is optional: UI
  checklist items are driven through one when reachable and marked `⚠️`
  unverified when not.
- The skill's `allowed-tools` are broad (`Bash`, plus read/edit/write, `Skill`,
  `AskUserQuestion`) because step 4 drives the local stack, which no narrow
  `gh`/`git` allowlist covers; consumer repos can mirror that in
  `.claude/settings.json` permissions to avoid prompts (see intendent for a
  worked example).

## `/colormath:qa` — QA a feature, then ship the fixes

Takes a focus area (`/colormath:qa the invite flow`) and QAs it against the
**running** stack, on the principle that a finding is a claim about a running
system and only counts once you've reproduced it:

1. **Scope** — maps the area to the routes, services, jobs and templates that
   implement it, and notes the trust boundaries it crosses.
2. **Recon** — brings the stack up (checking first whether it's already
   running, so it doesn't reseed someone's working environment) and collects
   credentials at *several* privilege tiers, including cross-tenant and any
   no-access role. A single admin account can't surface an authorization bug.
3. **Probe** — works three catalogs in `references/`: security (authorization
   matrix, confused-deputy, stored content served back, input validation),
   correctness (cross-surface consistency, write round-trips, contract drift),
   accessibility (keyboard, semantics, announcements, contrast). Sweeps before
   fixing anything.
4. **Verify** — reproduces every finding and reports the mechanism actually
   observed, not the assumed one. Separates pre-existing failures from real
   ones before attributing anything.
5. **Report and choose** — ranked findings with blast radius and repro, plus
   what came back clean and what wasn't covered; you pick what to fix.
6. **Fix, restore, ship** — re-runs each original repro against the running
   system (a green unit test isn't proof the bug is gone), undoes its test
   data and config changes, then hands off to `/colormath:ship`.

Local state is fair game — it writes rows, uploads files, mints credentials —
but it stops and asks before anything leaves the machine, because a dev `.env`
often holds a live provider key.

**Prerequisites:**

- A locally runnable stack, with the run commands and ports documented in
  `AGENTS.md` / `CLAUDE.md` (the skill reads these first).
- Seeded demo data with known accounts, ideally at several privilege tiers.
- `make preflight` and the `gates / *` check names — step 4 uses them to tell
  a genuine finding from local tool-version drift, and defers to CI when the
  two disagree.
- `/colormath:ship` for the handoff in step 6.

## `/colormath:bugfix` — a bug report, all the way to a merged fix

Takes a bug report (`/colormath:bugfix users can't log in with the account
they just created`) and carries it end to end, on the principle that a report
is *evidence, not a specification* — the expensive failure is forming a
plausible theory and proving it against the wrong environment or surface:

1. **Read the report, find what's missing** — separates what the report states
   from what you'd be assuming, and asks about the gaps that actually change
   the next action: which environment (production / staging / local / CI),
   which surface, the literal input and observed-vs-expected result, which
   privilege tier, when it started, and whether it's still producing bad data.
   Does a fast code pass *first* so the questions are concrete multiple choice
   rather than open interrogation, and batches them into one round. Skips the
   round entirely when the report is already reproducible as written.
2. **Reproduce against the running stack** — reuses the `qa` skill's
   `references/recon.md` for bringing the stack up without disturbing existing
   state and for credentials at the tier the report names, then drives the
   failure at the same surface over the real transport. For production
   reports it works the local/prod delta explicitly — configuration, data
   written before a constraint existed, migration state, scale — since that
   delta is frequently the bug. **Never modifies production.** If it can't
   reproduce, it stops and reports what it tried and ruled out rather than
   shipping a speculative fix.
3. **Diagnose the defect, not the symptom** — traces back from where the error
   surfaced to where the invariant went unenforced, and picks the *layer* to
   fix at so the bug can't re-enter through a sibling path (a check on one form
   leaves every other route in; the service chokepoint closes all of them).
   Enumerates those siblings and confirms the fix covers them.
4. **Fix with a regression test that earns its keep** — test at the layer the
   fix lives at, with the fail-then-pass ordering actually verified (stash the
   fix, watch it go red), then re-runs the original repro against the running
   stack, because a green unit test only proves the case you thought of.
5. **Remediate data the defect already corrupted** — characterizes affected
   rows with a real query, catches the constraint trap (a new `NOT NULL` /
   `CHECK` / unique index against existing violating rows fails or locks users
   out), puts the mechanically-repairable part in the same PR as an idempotent
   migration tested against locally-constructed broken data, and hands over
   what no script can recover instead of guessing at it.
6. **Ship** — commits to `fix/<slug>`, runs `make preflight` once, then hands
   off to `/colormath:ship` with a PR body carrying the report, the repro, the
   cause, why the fix sits at that layer, and the remediation.

**Prerequisites:**

- A locally runnable stack with run commands and ports in `AGENTS.md` /
  `CLAUDE.md`, and seeded accounts at several privilege tiers — same
  prerequisites as `/colormath:qa`, whose `references/recon.md` step 2 reads.
- `make preflight` (step 6) and `/colormath:ship` for the handoff.
- A browser is optional but makes UI-surface reproduction far more direct.

## `/colormath:gather-requirements` — settle what is being asked for

Takes a ticket **or an initiative** key
(`/colormath:gather-requirements CM-00001`) and establishes what the work
actually asks for, on the principle that a ticket is *a reminder, not a
specification* and an initiative is *a direction, not a design* — each carries
the trigger its author wrote down and none of the context they had in their
head:

1. **Read it, and work out which of the two you have** — `type` decides the
   deliverable. A **feature** or **bug** gets a description; an **initiative**
   gets a description *and* its feature definitions (and `initiative_status`
   decides whether those are still editable — once `building` the server
   refuses every feature write, and the skill says so up front rather than
   discovering it at the write step); a **task** gets a description and nothing
   else, ever, which makes this skill the whole of its grooming. Then the
   comments, the swimlane, the release, the parent, and — for an initiative —
   every feature in order plus the tickets already filed under it, which only
   `get_ticket` returns.
2. **Investigate before asking anything** — the written decisions first
   (`AGENTS.md`, `docs/adr/`, rules files), then the code it lands in: does it
   already exist or was it deliberately removed; which layer owns it; what it
   forces (a table, a migration, an event type, a permission, a deploy
   ordering); what it collides with; whether the wording is precise; whether
   this is one piece of work or several. For an initiative, also whether each
   feature is implementable as written and what the list is *missing*. Then it
   hunts specifically for **what makes it non-trivial**, since a one-line code
   change often hides the real work outside the diff — a DNS record, a verified
   vendor identity, a deploy that must reach two services.
3. **Interview until the picture is complete** — concrete multiple choice
   rather than an open survey, because step 2 already happened; batched into
   rounds, two at the ceiling for a ticket and three for an initiative. It asks
   about the problem behind the title, what "done" looks like as an observable,
   the scope edges, the forks step 2 surfaced, any architectural rule the work
   would need to bend, and the ordering. Where a conventional default exists it
   takes it and writes the assumption into the description instead of spending
   a question.
4. **Draft at the right altitude** — a description that stands alone: the
   problem, why it matters, the shape of the change, the real modules it lands
   in, acceptance criteria as observables a third person could check, the
   decisions taken and what they beat, the invariants it lives inside by ADR
   number, what is out of scope, and the surviving unknowns. For an initiative,
   each feature is rewritten as a capability someone could take — what it
   includes, what it does not, the observable that means it works — and the
   list is left in build order.
5. **Show, confirm, write back** — drafts everything in chat first, names what
   it would overwrite, then `update_ticket` (**description only**), then
   `update_feature` / `add_feature` / `move_feature`.

It **stops at the requirements**. No file-by-file steps, no signatures, no DDL,
no test lists — that is `/colormath:plan-ticket`'s altitude, and it
**never writes `plan` or `qa_plan`**, on any type. Naming a *module* as the
home for something is the right level here; naming a line is not. It never
bends an architectural rule silently: if the work needs one to move, that is a
question and then a line in the write-up. And it **never starts building** an
initiative — that transition is one-way, locks the features and cuts a ticket
per feature, so it is a person's decision and there is deliberately no tool for
it.

Two asymmetries it names rather than works around: there is **no delete tool**
for feature definitions, so a feature that should go is recommended for removal
and left to you in the web UI; and `update_feature` **replaces both fields**,
so it always sends the title.

**Prerequisites:**

- The **Abacus MCP server** connected, including the initiative tools
  (`get_ticket` returning `initiative_status` and `features`, plus
  `add_feature` / `update_feature` / `move_feature`). It is the plugin's one
  tracker dependency; without that server the skill has nothing to read or
  write.
- A checkout of the repo the work concerns, since step 2 is a real code and
  decision-record pass — gathering from the ticket text alone is the failure
  mode the skill exists to prevent.
- Nothing else: no running stack, no `gh`, no gates. The deliverable is the
  ticket.

## `/colormath:plan-ticket` — plan a gathered ticket until it can be worked

Takes a ticket key (`/colormath:plan-ticket CM-00001`) and turns a ticket whose
requirements are settled into one somebody could start on Monday. The failure
mode it exists to prevent is **the plan of generic steps** — "update the
relevant service", "add tests", "verify it works" — which names nothing, could
have been written without opening the repo, and cannot be wrong in a way anyone
can catch:

1. **Read it, and check this is the right skill** — a **feature** or **bug**
   carries plans; an **initiative** is the wrong altitude (its plans belong to
   the tickets cut from it) and a **task** carries none by design, so both
   stop here with a pointer. Then it checks the requirements are actually
   settled — can you say from the ticket alone what problem this solves, what
   "done" looks like, and what is out of scope — and hands back to
   `/colormath:gather-requirements` rather than inventing the missing half.
2. **Investigate the code, at the altitude gathering avoided** — which files
   actually change and in what order, which *layer* the change belongs at and
   why there rather than where the symptom appears, what else reaches that code
   (the regression surface), what the existing tests already cover, and what
   has moved since the description was written. Then what the diff *won't*
   contain: a migration that must land in order, a backfill for rows written
   under the old behavior, a credential someone has to issue.
3. **Settle the forks — and only the forks** — the requirements interview
   already happened, so there should be very few: where new state lives, what
   happens to existing data, shipping order, an invariant the plan would have
   to bend. One round, four questions at most, and none at all when nothing is
   genuinely open.
4. **An implementation plan someone could follow** — prerequisites and blockers
   first, then ordered steps naming **real paths** (a step that names no file
   is a wish), the layer the change belongs at, what explicitly *doesn't*
   change, honest sizing, and the open questions that survived.
5. **A QA plan someone can execute** — happy path, authorization and tenancy,
   the edges the change introduces, regression surface, data written under the
   old behavior, accessibility, post-deploy checks; then splits what the test
   suite covers from what needs hands, and names the gates the change
   implicates. Written knowing `/colormath:ship` will execute it verbatim
   against a running stack.
6. **Show, confirm, write back** — drafts in chat first, calls out any text it
   would overwrite that it didn't write, then on approval writes **two**
   distinct fields (`plan`, `qa_plan`) rather than folding QA into the plan,
   since a ticket only reads as ready once both are set.

It **never writes `description`** — that is `gather-requirements`' field, and
the person who scoped the ticket owns it; where the investigation shows the
description is wrong, that is a finding and a pointer back, not a quiet
rewrite. It plans and stops: no branches, no code edits, no PRs, and no
creating, splitting or moving tickets as a side effect. When the investigation
shows the ticket shouldn't be built at all — already built, already rejected,
or solving a problem that no longer exists — that finding is the deliverable
instead of a dutiful plan.

**Prerequisites:**

- The **Abacus MCP server** connected — this skill keys on `get_ticket` /
  `update_ticket` / `add_comment` and on Abacus keeping `plan` and `qa_plan` as
  fields separate from `description`.
- A checkout of the repo the ticket concerns, since step 2 is a real code pass
  at file-and-line level — planning from the ticket text alone is the failure
  mode the skill exists to prevent.
- Nothing else: no running stack, no `gh`, no gates. The deliverable is the
  ticket.

## `/colormath:plan-initiative` — plan a whole initiative, in order

Takes an initiative key (`/colormath:plan-initiative CM-00007`) and runs
`plan-ticket` over every ticket under it, one at a time, in build order:

1. **Check it can be planned** — it is an initiative, and its tickets exist. They
   are cut when a human starts building, so a `designing` initiative has none:
   the skill says so and points at `gather-requirements` rather than starting
   the build to unblock itself.
2. **Establish the order and show the run** — children sorted by position (build
   order, carried down from the feature list), which are already planned, which
   are **tasks** and therefore unplannable by design, which have descriptions
   too thin to plan against (those need `gather-requirements` first), and how
   many plannings the user is about to sit through. A seven-ticket initiative
   is a long session, and someone who knows that up front can say "just the
   first three today".
3. **Plan each one with its place in the sequence** — invokes
   `/colormath:plan-ticket` with the key first, then the context that skill
   cannot see: the initiative and its settled decisions, "ticket 3 of 7", what
   came **before** it and *what those plans actually decided*, what comes
   **after** it so this one doesn't absorb it, and the feature definition it was
   cut from.
4. **Carry the answers forward** — what the user answers for ticket 2 is injected
   into ticket 3, so the questions thin out as the run goes rather than repeating.
5. **Verify, then report** — re-reads each ticket and counts it planned only when
   both `plan` and `qa_plan` are actually set. Finishes with the per-ticket state
   plus what only becomes visible from up here: contradictions it reconciled,
   gaps the tickets don't cover, and tickets that shouldn't exist.

The reason it exists is the seams. Run by hand seven times, `plan-ticket`
plans seven strangers: it re-derives the same background each time, asks the
same question each time, and produces plans that each make locally sensible
choices that contradict each other where they meet.

It holds no `update_ticket` tool — it never writes a plan itself, which is
`plan-ticket`'s job — and no `Edit`/`Write`, so it cannot touch the repo. It
does not create, split, re-type or delete tickets, and it does not start
building.

**Prerequisites:** the **Abacus MCP server**, a checkout of the repo (every
`plan-ticket` call does a real code pass), and an initiative that has already
started building. Nothing else.

## `/colormath:implement-ticket` — build a planned ticket and ship it

Takes a ticket key (`/colormath:implement-ticket CM-00012`) and takes a groomed
ticket the rest of the way. The thinking already happened in
`gather-requirements` and `plan-ticket`; this is where it meets the code:

1. **Read it and check it can be built** — no implementation plan means back to
   `plan-ticket`, because a plan written by the same run that implements it has
   never been read by anyone. A **task** carries no plans by design and is not
   code work; an **initiative** is the wrong altitude. Reads the parent
   initiative too when there is one, so the build doesn't collide with the ticket
   next to it.
2. **Check the plan against the code before touching anything** — the plan was
   written against the codebase as it *was*: files move, adjacent changes land,
   assumptions expire. Every step is walked against the repo, and where it no
   longer holds that is a **finding for the user**, not something to route around
   silently. Sometimes the most valuable outcome here is "this plan no longer
   holds, here's why" rather than a PR.
3. **Ask only what actually blocks** — by this point there is usually nothing;
   grooming's whole job was to remove it. One round, and wanting several rounds
   means the ticket isn't groomed and should go back.
4. **Build it at the layer the plan names**, on a branch, in the idiom of the
   surrounding code, with tests at the layer the change lives at. Deviations from
   the plan are recorded in chat, the PR body and a ticket comment — never by
   rewriting the plan field, which would erase the difference between what was
   intended and what happened.
5. **Execute the QA plan against the running stack** — every item gets an
   observation, `⚠️` when no browser is reachable for a UI item, and a failure is
   fixed and re-run rather than shipped with the document claiming it passed.
6. **Ship** — `make preflight`, then `/colormath:ship` for PR, gates, review, a
   second pass over the same QA plan, and the merge decision. Comments the
   outcome back onto the ticket.

It leaves the ticket's own fields alone: `plan` and `qa_plan` are the record of
intent, the comment is the record of what happened. It does not move tickets
between lanes — one project's "In Review" is another's "Staging", and guessing at
somebody's workflow is worse than leaving it where they put it.

**Prerequisites:** the **Abacus MCP server**, a checkout with the stack runnable
(step 5 is real QA, not a test run), and `/colormath:ship`'s own prerequisites,
since it hands off there.

## Adding a skill

One directory per skill: `skills/<name>/SKILL.md` with frontmatter
(`name`, `description`, optional `argument-hint` / `allowed-tools` / `model`).
The directory name is the command name (`/colormath:<name>`). Document the
skill in this README, keep it consumer-agnostic (no product names, no
hardcoded default branch), and note in the changelog which contract surfaces
it depends on — a rename of any of them must ship with the skill update in
the same release.
