---
name: bugfix
description: Take a bug report all the way from raw report to merged fix — establish the facts the report left out (which environment, which surface, the literal repro), reproduce the defect against the running stack, fix it at the layer the invariant belongs to, add a regression test that fails without the fix, assess whether the defect already corrupted stored data and remediate that in the same PR, then hand off to /colormath:ship. Use this whenever someone reports something broken — a ticket key for a filed bug, a bug report, a pasted stack trace or error log, "why is X doing Y", "users can't Z", a production incident, a written-up findings doc — even when they never say the word "bug". Not for sweeping a whole feature area for unknown problems (that's /colormath:qa), and not for shipping a branch that's already fixed (that's /colormath:ship).
argument-hint: [a ticket key (CM-00012), or the report itself — prose, a pasted error/log, or a path to a report file]
allowed-tools: Bash Read Edit Write Grep Glob Skill AskUserQuestion mcp__abacus__get_ticket mcp__abacus__record_metric mcp__abacus__add_comment mcp__abacus__get_project mcp__abacus__move_ticket mcp__abacus__list_projects mcp__abacus__list_tickets
---

Turn the bug report in "$ARGUMENTS" into a merged fix.

A bug report is **evidence, not a specification**. It tells you what one person
noticed from outside the system; it rarely tells you where they were standing,
what they actually typed, or what the system did underneath. The failure mode
this skill exists to prevent is the natural one: read the report, form a
plausible theory, and spend an hour proving it against the wrong environment,
the wrong surface, or a bug that was never there. The cure is cheap — a few
targeted questions cost the reporter seconds, and reproducing the failure once
costs you minutes and converts every later step from guesswork into
verification.

So the spine is: **understand → reproduce → diagnose → fix → prove → remediate
→ ship.** Don't skip forward. In particular, don't start editing code before
you have watched the bug happen.

**First, work out what you were handed.** A bug arrives in one of three
shapes, and they start differently:

- **A ticket key** (`CM-00012`, `cm-12` — case and zero-padding don't matter).
  Call `mcp__abacus__get_ticket`, which takes the key directly. Read the whole
  thing: description, type, **every comment**, and the plan and QA plan if
  somebody groomed it. The comments are where the report actually lives once a
  bug has been discussed — the reproduction somebody finally landed on, the
  environment it was seen in, the "actually it also happens when…" that never
  made it into the description. A bug filed as a ticket has usually been talked
  about, and skipping the thread is how you re-derive what the thread already
  settled. If "$ARGUMENTS" is a title fragment rather than a key, find it with
  `list_projects` then `list_tickets`, and confirm which one you landed on before
  doing anything else.
- **A file** — a written-up report, an exported ticket, a QA findings doc. Read
  the whole thing first.
- **Prose, a stack trace, or a log excerpt**, pasted straight in. A trace is
  your best evidence: work backwards from the frames to the code path, but
  treat it as the *symptom's* location, not the defect's.

Whichever it was, the ticket or the report is still **evidence rather than a
specification**, and step 1 applies unchanged. A filed ticket is not more
authoritative than a pasted paragraph — it is the same claim with a number on
it, and the same things are missing from it.

## 1. Read the report, then find what's missing

Separate what the report actually **states** from what you are **assuming**.
Write both down for yourself. The assumptions are your question list.

These are the unknowns that most often send a fix down the wrong path:

- **Which environment.** Production, staging, a local dev stack, CI? This
  changes almost everything downstream: whether stored data is already
  corrupted, how urgent it is, what you're allowed to touch, and whether the
  code on the reporter's screen is even the code in your working tree.
- **Which surface.** The same user-visible symptom usually has several possible
  entry points — a public form, an invite acceptance, an admin action, an API
  client, a background job. Each has different code and different validation.
- **What literally happened.** The exact input, the exact steps, the observed
  result, and the expected result. Vague verbs are the big trap: "it's not
  recognizing it", "it doesn't work", "it fails" each describe several distinct
  bugs. Pin the verb down to an observable.
- **Which identity.** The account, its privilege tier, its tenant/org. Bugs
  that only bite one role are common and invisible if you test as an admin.
- **When it started**, and whether it reproduces for the reporter every time or
  happened once.
- **Blast radius.** One user or everyone; blocking or cosmetic; and — the
  question people forget — is it still actively producing bad data right now?

**Do a fast code pass before you ask.** Ten minutes of grepping the relevant
surfaces turns open-ended interrogation ("which surface?") into a concrete
multiple choice ("public signup form, invite acceptance, or admin-created
user?"). Concrete options are dramatically cheaper for the reporter to answer
and they surface the possibilities they hadn't considered. This is what
`AskUserQuestion`'s option lists are for.

**Ask only what changes what you'd do next**, and ask it in one batch rather
than trickling questions out over several turns. If the answer to a question
wouldn't alter your next action, you already have enough — proceed. If the
report is already specific enough to reproduce from, skip this step entirely
and say so.

If something is genuinely urgent — actively corrupting data, or blocking every
user — say that up front and offer the fastest safe path, rather than working
methodically through a long diagnosis while the bleeding continues.

**If this came from a ticket, keep its current `swimlane_id`.** The next step
moves it, and this is what puts it back if the run ends without a fix.

## 2. Say on the project that somebody is on it

If there is a ticket, move it into the column this skill leads into — **now,
before you try to reproduce anything**, not when the fix is written.

The column is a claim in the present tense: somebody is on this bug. A move
made at the end has never once been true while it was true. The ticket spends
its entire working life — bringing the stack up, reproducing, tracing the cause,
writing the fix and the regression test, remediating the data — sitting wherever
it was filed, so anybody looking at the project during exactly the window when a
second person might pick the same bug up sees a bug nobody has touched. The
column then flickers past on the way to ship. A lane that no ticket is ever
observed in is a lane that is not doing anything.

This is the first step that costs anything, which is what makes it the right
place. Step 1 was reading and asking; from here on you are running a stack and
editing code, and that is the part worth claiming.

**Ask the project where; never name a column.** Call `mcp__abacus__get_project`
with the ticket's `project_id`. It returns the swimlanes **in the project's own order**, each
carrying `exit_commands` — the commands that move work *on from* that column.
Each entry says its `skill`, the whole `command` line, and `leads_to` — the id
of the swimlane that command moves the ticket into.

Find the entry whose `skill` is `bugfix`; match on that field rather than on the
command line, whose plugin half is configuration and differs per project. Then
`mcp__abacus__move_ticket` with that entry's `leads_to` as the `swimlane_id`,
and `position: 0`. The destination is stated, so do not count lanes yourself —
"the one after the lane I matched" is arithmetic whose one wrong answer sends
every ticket backwards.

This used to be forbidden, and the reason is worth knowing: lane meaning was per
project and free text, so one team's "In Review" was another's "Staging" and
guessing at somebody's workflow was worse than leaving the ticket alone. Abacus
columns now come from a project schema and say for themselves which skill leads
into them, so there is nothing left to guess.

**The move says somebody is on this bug, and only that.** Whether the fix then
goes through the PR pipeline is `ship`'s move to make, one column further on —
which is also why the ticket has to be *here* before ship runs, rather than
still in the column behind it.

**Put it back if you stop without a fix.** Step 3 can end in "cannot reproduce",
which is a real outcome and a good one. When it does, `move_ticket` the ticket
back to the `swimlane_id` you kept in step 1, say in your report that you did,
and stop. A bug parked in Implementing with nobody fixing it is a worse lie than
the one this step exists to correct.

Four cases where you do not move it, each reported rather than retried:

- **There is no ticket.** A bug pasted in as prose or a stack trace has nothing
  to move. Say so once and carry on; the fix does not depend on being filed.
- **No column names this skill** — a Task Tracker names none, and neither does a
  project on a schema that runs a different process. Say the project does not
  describe this step, and carry on: the work is not conditional on the project
  being able to describe it.
- **The ticket is in no column at all.** The move is refused: *"Plan this ticket
  for a release, or file it under an initiative, before giving it a status."*
  A bug reported straight into the backlog is the common case; report it and
  carry on.
- **The move fails otherwise.** Say so plainly and carry on. A ticket in the
  wrong column is a smaller problem than a report claiming a move that did not
  happen — and a smaller problem than not fixing the bug.

## 3. Reproduce it against the running stack

A fix that isn't anchored to a failure you watched happen is a guess. This step
is what makes the rest trustworthy, and it's the one worth slowing down for.

Read the `qa` skill's `references/recon.md` before touching anything: bring the
stack up **only if it isn't already running** (don't reseed a working
environment out from under someone), and get credentials at the privilege tier
the report names — not just the most convenient admin account.

Reproduce at **the same surface and the same tier** the reporter used. Drive it
over the real transport — a browser for UI, `curl` or a small driver script for
API and backend paths — rather than calling functions in-process, because
in-process calls skip exactly the middleware, validation and serialization
layers where the defect often lives.

**Write the repro down as something runnable.** You'll use it three more times:
to confirm the diagnosis, to prove the fix, and as the seed of the regression
test. A one-line script beats a remembered sequence of clicks.

### When the report is from production

The local stack is not production, and the difference between them is often the
bug. Before concluding "cannot reproduce", work through what differs:

- **Configuration** — env vars, feature flags, providers wired to real services
  versus local fakes, different limits or timeouts.
- **Data that predates the current code.** Rows written before a constraint,
  validation, or migration existed will violate rules the current code assumes
  hold. Local seed data is usually pristine and therefore hides this entire
  class. Seeding a row in the shape the report implies is a legitimate way to
  reproduce.
- **Migration state** — a migration applied locally but not there, or vice versa.
- **Scale and concurrency** — races and N+1 collapses that only appear under
  real load or real row counts.

**Never modify production to investigate.** Reproduce locally, including by
constructing local data that mimics the production state you believe exists.

### If it won't reproduce

Stop and report — do not ship a speculative fix. Say plainly that you couldn't
reproduce it, then give the reporter something useful to push back on: what you
tried (surface, tier, inputs), what you *ruled out* and how, your leading
hypothesis and the specific piece of information that would confirm or kill it.
Often the missing piece is one detail the reporter can supply in seconds. A
wrong fix shipped confidently is worse than an honest "I need one more thing"
— it burns a review cycle and leaves the real bug live.

Move the ticket back to the column step 2 took it out of before you stop, and
say in your report that you did. This is the exit that step's "put it back"
paragraph was written for.

## 4. Diagnose: find the defect, not the symptom

The place an error *surfaces* is usually not the place it's *caused*. Trace
backwards from the observed failure until you reach the point where the system
first did the wrong thing — the moment a bad value was accepted, an invariant
went unenforced, a wrong branch was taken.

Then choose **the layer to fix at**, which is the decision that determines
whether this bug comes back. Fix where the invariant genuinely belongs, not
where it happened to be noticed. A validation added to one form leaves every
other route into the same invariant broken; the same rule enforced at the
service or model chokepoint closes all of them at once. Client-side checks are
never the fix — they're a nicety on top of a server-side rule.

**Enumerate the siblings.** A defect that reached users through one path
usually has siblings on the other paths into the same invariant: the other
callers of the function, the other routes that write the same field, the
background job that does the same work without the form's guard. Find every
entry point and confirm your chosen fix covers them. Fixing one and leaving
three is how a bug gets reported twice.

Keep the scope honest in the other direction too: fix **this** bug and its
siblings. When you notice unrelated problems nearby — and you will — write them
down and mention them at the end. Folding them in bloats the diff, muddies the
review, and makes it harder to tell what actually fixed the reported symptom.

## 5. Fix it, and prove the fix with a regression test

Make the change in the idiom of the surrounding code, following the repo's
`AGENTS.md` / `CLAUDE.md` conventions and its layering rules.

Add a regression test **at the layer the fix lives at** — the chokepoint you
chose in step 4, so the test guards the rule itself rather than one caller of
it.

**Verify the test actually catches the bug.** A regression test that passes
with and without the fix is decoration. Prove the ordering: write the test
first and watch it fail, or temporarily revert the fix (`git stash`) and confirm
the test goes red, then restore and watch it go green. This takes a minute and
is the difference between a test that pins the behavior down and one that just
looks reassuring.

Then **re-run the original repro from step 3** against the running stack. A
green unit test is not proof the bug is gone — it proves the case you thought
of is gone. The repro is what the reporter actually did.

## 6. Remediate data the defect already corrupted

The code fix stops the bleeding. It does nothing about what already leaked —
and for a production bug, that's usually the half that matters to real users.
This step is skippable only when you've established the defect couldn't
persist bad state; say so explicitly rather than silently passing over it.

Ask: could this defect have written bad rows, files, or cached values? If so:

- **Characterize it precisely.** Write the query that identifies affected
  records. "Some users might be affected" is not actionable; "rows where X is
  set and Y is null" is.
- **Watch for the constraint trap.** If your fix adds a `NOT NULL`, `CHECK`,
  unique index, or newly-strict validation, existing violating rows will either
  fail the migration outright or lock those users out of a working system. The
  backfill has to land before or within the same migration as the constraint —
  check this explicitly, because it usually fails only in the environment that
  has the bad data, which is the one you can't test in.
- **Decide who can fix each row.** Some corruption is mechanically repairable
  (derive the right value, normalize the format) and belongs in a migration or
  backfill script in this same PR. Some genuinely isn't — information the
  defect destroyed can't be recovered by a script, and guessing at it is worse
  than leaving it. Put the repairable part in the PR and hand the rest over
  explicitly: name the affected records, say what a human needs to decide, and
  suggest how to reach them.
- **Test the remediation against local data shaped like the real thing.**
  Construct rows in the broken state, run the migration, confirm they come out
  right and that already-good rows are untouched. Confirm it's idempotent — a
  re-run must be a no-op, because it will be re-run.
- **Never run it against production yourself.** Ship it as a migration or a
  reviewed script, following the repo's migration conventions.

## 7. Ship it

The ticket has been sitting in the right column since step 2, which is what
`ship` needs: it moves the ticket on from *this* column, and a ticket still in
the one behind would be moved from the wrong place.

- Commit on a branch — `fix/<short-slug>` — never on the default branch.
- Run the repo's full local gate mirror once (`make preflight`) before handing
  off, so an avoidable failure doesn't cost a CI round trip.
- Then invoke `/colormath:ship`, which takes it the rest of the way: PR, gates,
  review, the ticket's QA plan executed against the running stack, fixes for
  anything that turns up, either an auto-merge when it's genuinely clean or a
  hold with the reason — and the next move on the project.

Give ship a PR title naming the user-visible symptom, and make sure the body
carries what a reviewer needs and no reviewer can reconstruct on their own:
**the report** as received, **the repro** you ran, **the cause** you found,
**why the fix sits at that layer**, and **the data remediation** — including
anything you deliberately left for a human.

## 8. Record that you ran

Abacus cannot see this happen. Nothing outside your own run knows a skill
started, so a run you do not record did not happen as far as the ticket is
concerned — and the counts worth having are the ones nobody wants: a bug fixed
twice is a bug whose cause was never found, and the second fix reads exactly
like the first.

`mcp__abacus__record_metric` with the ticket's `id`, `metric: "skill_invoked"`,
and `subject: "bugfix"` — the bare name, never the whole command, because the
plugin half is configuration and differs per project.

**Once, at the end, and only if you did the work.** Not on every turn and not
when you begin — a skill that reports each time it thinks makes the count
meaningless. The project move in step 2 is deliberately the other way round, and
the two are not in tension: a column is a claim about what is happening now, so
it is only useful said early, while a metric is a record of what happened, which
cannot be written until it has. If you were interrupted, or you stopped at
step 3 because you could not reproduce it, record nothing: a run that did not happen must not
leave a row saying it did.

**The rows are append-only.** Nobody can edit or delete one, you included, so a
wrong subject or a double-record is permanent. Get it right rather than
expecting to correct it.

If there is no ticket, or the call fails, say so in your report and carry on.
The work is done either way, and a report claiming a measurement it did not
take is worse than a missing row.

## Rules

- **Reproduce before you fix.** If you couldn't reproduce it, stop at step 3
  and report — never ship a speculative fix without saying plainly that it's
  reasoned rather than observed.
- **Never modify production**, and never run a remediation against it yourself.
  Investigation and repair both happen locally; production changes land through
  the PR.
- **Ask before anything leaves the machine** — outbound email through a
  configured provider, third-party API calls, writes to any shared environment.
  A dev `.env` often holds a *live* key, so "it's only the dev stack" is not a
  reason to assume a send won't really deliver. Offer to redirect locally.
- **Move the ticket when you start, not when you finish.** The column says
  somebody is on this bug; said at the end it was never true while it was true.
  Stop without a fix and you move it back.
- **Fix the reported bug and its siblings**, not everything you notice. Adjacent
  problems get written down and mentioned, not folded into the diff.
- Local state is yours to mutate while reproducing — record a baseline first so
  you can put it back, and clean up the rows, files and credentials you created.
- **If it came from a ticket, close the loop on it.** When ship comes back,
  `add_comment` with the outcome — the PR link, whether it merged or is held,
  the cause you found, and what you deliberately left alone. Leave the ticket's
  own fields alone: the description is what was reported, and the comment is
  what happened.
- Your job ends where `/colormath:ship` takes over, and ship's own rules apply
  from there.
