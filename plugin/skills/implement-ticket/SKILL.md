---
name: implement-ticket
description: Take a planned ticket all the way to a shipped PR — check its plan still matches the code, ask only what genuinely blocks, build it at the layer the plan names, execute its QA plan against the running stack, then hand off to /colormath:ship. Use this when someone says to implement, build, do, or work a ticket that has already been groomed, or names a ticket key and says "go". Not for grooming (that's /colormath:gather-requirements, then /colormath:plan-ticket) and not for a defect report (that's /colormath:bugfix).
argument-hint: [ticket key, e.g. CM-00012]
allowed-tools: Agent Bash Read Edit Write Grep Glob Skill AskUserQuestion mcp__abacus__get_ticket mcp__abacus__record_metric mcp__abacus__add_comment mcp__abacus__get_project mcp__abacus__move_ticket mcp__abacus__list_projects mcp__abacus__list_tickets
---

Implement the ticket in "$ARGUMENTS", QA it, and ship it.

The ticket has already been groomed — `/colormath:gather-requirements` wrote
the description, and `/colormath:plan-ticket` wrote an implementation plan
whose steps name real files and a QA plan someone could execute. **Your job is
to execute that, not to redo it.** The thinking happened; this is where it
meets the code.

The one thing that makes this more than typing: **the plan was written against
the codebase as it was.** Between grooming and now, files moved, an adjacent
change landed, an assumption expired. A plan executed blindly produces a diff
that satisfies the letter of a document and breaks the thing it was for. So the
first act here is checking the plan still describes reality, and the most
valuable outcome is sometimes "this plan no longer holds, here's why" rather
than a PR.

## 1. Read the ticket and check it is ready to build

Call `mcp__abacus__get_ticket`. It takes the key directly; case and padding
don't matter. If "$ARGUMENTS" is a title fragment, resolve it with
`list_projects` / `list_tickets` and confirm which ticket you landed on.

Read all of it — description, **implementation plan**, **QA plan**, every
comment, type, and the initiative it belongs to if it has one. Comments carry
decisions made after the plan was written, and they win.

Then check it can be implemented at all:

- **No implementation plan** — stop. This skill executes a plan; it does not
  write one. Send them to `/colormath:plan-ticket <key>` and say why: a plan
  written by the run that implements it has never been read by anyone.
- **No QA plan** — say so and ask whether to continue. You can implement without
  one, but nothing will check the result the way a groomed ticket intends, and
  the honest thing is to let them choose rather than inventing acceptance
  criteria at the moment they'd be most convenient.
- **A task** — that type carries no plans by design. It is not code work; it is
  a chore somebody does. Say so and stop.
- **An initiative** — the wrong altitude. Its tickets are what get implemented;
  `/colormath:plan-initiative` plans them, then this skill takes them one at a
  time.

If the ticket belongs to an initiative, read that too. The initiative says what
the whole thing is for and what the neighbouring tickets are doing, which is how
you avoid building something that collides with the ticket after it.

**Keep the ticket's current `swimlane_id`.** The next step moves it, and this is
what puts it back if the run ends without building anything.

## 2. Say on the project that somebody is on it

Move the ticket into the column this skill leads into — **now, before you read a
line of the code**, not when the work is done.

The column is a claim in the present tense: somebody is building this. A move
made at the end has never once been true while it was true. The ticket spends
its entire working life — the hours of reading, building and QA where a
collision actually costs something — sitting in Ready for Implementation, and
anybody looking at the project during exactly that window sees work nobody has
picked up. The column then flickers past on the way to ship. A lane that no
ticket is ever observed in is a lane that is not doing anything.

The gate above is what makes this safe to do first. By here the ticket exists,
has an implementation plan, is a type that can be built, and is going to be
built. What is left is whether the plan still holds, and there is a way back for
that below.

**Ask the project where; never name a column.** Call `mcp__abacus__get_project` with
the ticket's `project_id`. It returns the swimlanes **in the project's own order**, each
carrying `exit_commands` — the commands that move work *on from* that column.
Each entry says its `skill`, the whole `command` line, and `leads_to` — the id
of the swimlane that command moves the ticket into.

Find the entry whose `skill` is `implement-ticket`; match on that field rather
than on the command line, whose plugin half is configuration and differs per
project. Then `mcp__abacus__move_ticket` with that entry's `leads_to` as the
`swimlane_id`, and `position: 0`. The destination is stated, so do not count
lanes yourself — "the one after the lane I matched" is arithmetic whose one
wrong answer sends every ticket backwards.

This used to be forbidden, and the reason is worth knowing: lane meaning was per
project and free text, so one team's "In Review" was another's "Staging" and
guessing at somebody's workflow was worse than leaving the ticket alone. Abacus
columns now come from a project schema and say for themselves which skill leads
into them, so there is nothing left to guess.

**The move says somebody is building this, and only that.** Whether the code
then goes through the PR pipeline is `ship`'s move to make, one column further
on — which is also why the ticket has to be *here* before ship runs, rather than
still in the column behind it.

**Put it back if you hand the ticket off instead.** Steps 3 and 4 can end with
the plan no longer describing the code and the ticket going back to
`/colormath:plan-ticket` or `/colormath:gather-requirements`. When that happens,
`move_ticket` it to the `swimlane_id` you kept in step 1, say in your report
that you did, and stop. A ticket parked in Implementing with nobody implementing
it is a worse lie than the one this step exists to correct.

Three cases where you do not move it, each reported rather than retried:

- **No column names this skill** — a Task Tracker names none, and neither does a
  project on a schema that runs a different process. Say the project does not
  describe this step, and carry on building: the work is not conditional on the
  project being able to describe it.
- **The ticket is in no column at all.** The move is refused: *"Plan this ticket
  for a release, or file it under an initiative, before giving it a status."*
  That is correct; report it and carry on.
- **The move fails otherwise.** Say so plainly and carry on. A ticket in the
  wrong column is a smaller problem than a report claiming a move that did not
  happen — and a smaller problem than not building the ticket.

## 3. Check the plan against the code before you touch anything

Walk the plan step by step with the repo open. For each step:

- **Does the file still exist, at that path?** A renamed module means the plan
  is describing a codebase that no longer exists.
- **Does the surrounding code still look like the plan assumes?** The function
  it says to extend, the layer it says to add to, the caller it says will pick
  the change up.
- **Has any of it already been done?** By the ticket next to it in the
  initiative, or by an unrelated PR that passed through.
- **Do the repo's conventions still allow it?** `AGENTS.md` / `CLAUDE.md`, the
  ADRs, the rules files. A plan that was fine in March can violate a decision
  recorded in April, and the decision wins.

Where the plan holds, say so briefly and move on. Where it does not, that is a
**finding**, and it goes to the user in step 4 rather than being quietly
routed around. Silently improving a plan is how a reviewed decision gets
replaced by an unreviewed one.

Then scan the plan's steps against each other. Step 3's first pass checked
each step against the code. This pass checks the steps against one another:

- **Do the interfaces match?** Each step states what it consumes and what it
  produces. Verify that what step N says it produces is what step N+1 says
  it consumes — the same function names, the same types, the same data
  shapes. A mismatch here means two subagents will build to different
  contracts.
- **Do any steps contradict each other?** Two steps that both create the
  same file, or that make incompatible assumptions about the same function,
  will collide when built in sequence.
- **Does anything the plan mandates contradict the repo's conventions?** A
  plan step that names a pattern the repo has since replaced, or that puts
  code in a location the conventions now forbid, will pass review and rot.

Write the results to a progress ledger file at
`.colormath/sdd/<ticket-key>/progress.md`. Create the directory if it does
not exist (`mkdir -p`), and ensure `.colormath/` is in the repo's
`.gitignore` (add it if missing — the workspace is scratch, not source).
Start the ledger with `# Ledger — ticket: <ticket key>` as its first line. Record the scan
as a table: one row per pair of adjacent steps that share an interface, and
one row per step that touches a convention-governed location. "The scan is
clean" without those rows is not a scan you ran.

Rule on every finding before you proceed. The ticket description and the
initiative are the authorities. Record each ruling in the ledger as
`Ruling: <decision> — <why> — <cost if wrong>`. If the scan is clean,
proceed without comment.

## 4. Ask only what actually blocks you

By this point there usually is nothing to ask — grooming's whole job was to
remove these, and a skill that reopens settled questions has wasted the
grooming. Ask only when you genuinely cannot proceed:

- the plan no longer matches the code and there is a real choice about what to
  do instead;
- two readings of a step produce materially different, user-visible results;
- the plan needs something the repo cannot give itself — a credential, a vendor
  account, a decision that belongs to someone else.

One round, `AskUserQuestion`, concrete options, recommendation first. Anything
you can settle from the ticket, the initiative, the ADRs or the conventions is
not a question. And if you find yourself wanting several rounds, the ticket is
not groomed and should go back to `/colormath:gather-requirements` — say that
instead of interviewing your way to a design.

Handing the ticket back is one of the two good outcomes here, and it has a
project move of its own: put the ticket back in the column step 2 took it out of
before you stop.

## 5. Build it, one step at a time

Branch first — `feat/<ticket-key-slug>` or the repo's own convention — never
the default branch.

This skill is a coordinator. It reads the plan, dispatches a fresh subagent
per step, reviews each step's output, and moves on. It does not write code
itself. The subagents write code. The coordinator dispatches, reviews, rules
on ambiguities, and keeps the ledger.

### The ledger

The progress ledger at `.colormath/sdd/<ticket-key>/progress.md` (created
in step 3) is your recovery map. It survives context compaction. If this
session's context is compressed, trust the ledger and `git log` over your
own recollection.

If a ledger already exists for this ticket and its first line names this
ticket's key, resume from where it left off. A step with a
`Step <N>: complete` line is done — do not re-dispatch it. A step whose
last line is a fix round is mid-loop — resume the loop at the next round.
A ledger whose first line names a different ticket is not yours; leave it
and start a fresh one.

### Dispatch each step

For each plan step, in order:

**1. Record BASE.** Run `git rev-parse HEAD` before dispatching. The review
diff and fix-round diffs need this.

**2. Write the step brief to a file.** Save the step's full text (including
its interfaces) to `.colormath/sdd/<ticket-key>/step-<N>-brief.md`. This
file is the subagent's requirements.

**3. Dispatch a fresh implementer subagent.** The dispatch contains:

- One line on where this step fits ("step 3 of 7, after the migration, before
  the API route").
- The brief file path, introduced as "read this first — it is your
  requirements."
- Decisions from earlier steps that this step must match — by interface, not
  by summary. Keep it to the exact function names, types, and data shapes
  the brief's `consumes` section names.
- Global context from the ticket and initiative: what the ticket is for,
  the acceptance criteria, and any conventions the step must follow.
- The report file path (`.colormath/sdd/<ticket-key>/step-<N>-report.md`)
  and the report contract: the subagent writes its full report there and
  returns only status, commits, a one-line test summary, and concerns.

**Never make the subagent read the whole plan.** It sees its step, its
interfaces, and the global context. Nothing else.

**The no-subagents contract.** The implementer never dispatches subagents of
its own — not helpers, not reviewers. Review comes from the coordinator
after the report. Say this in the dispatch.

**4. Handle the report.** The implementer returns one of four statuses:

- **DONE** — proceed to the task review.
- **DONE_WITH_CONCERNS** — read the concerns. If they are about correctness
  or scope, address them before review. If they are observations ("this file
  is getting large"), note them in the ledger and proceed to review.
- **NEEDS_CONTEXT** — provide the missing context and re-dispatch.
- **BLOCKED** — assess: a context problem means re-dispatch with more
  context; a reasoning problem means re-dispatch on a more capable model; a
  plan defect means rule on the correction, ledger the ruling, and
  re-dispatch with the ruling in the dispatch.

Never ignore an escalation. If the implementer said it is stuck, something
needs to change.

**5. Review the step.** Write the diff to a file: `git diff BASE..HEAD`
redirected to `.colormath/sdd/<ticket-key>/step-<N>-review.diff`. Dispatch
a fresh reviewer subagent with: the diff file, the brief file, the report
file, and the ticket's acceptance criteria. The reviewer checks **spec
compliance and code quality**. Both verdicts are required. Never skip the
task review, and never accept a report that is missing either verdict.

**6. The fix loop.** The loop starts when the review reports a spec failure,
a Critical or Important finding, or a "cannot verify from diff" item you
confirmed as a real gap. Five rounds maximum:

- **Rounds 1–3:** resume the original implementer with the open findings.
  Its context is intact. If your harness cannot resume a live subagent,
  dispatch a fresh one with the brief, the report file, and the findings.
- **Rounds 4–5:** dispatch a fresh implementer on a more capable model, with
  the brief, the report file, the findings, and this framing: "A prior
  implementer attempted this step [N] times; you own it now. Read the report
  file for what was tried."
- **Every round:** the implementer fixes, re-runs the covering tests, and
  appends a fix report to the same report file. Then dispatch a scoped
  re-review: write the fix diff (`git diff FIX_BASE..HEAD`) to a file, and
  give the reviewer the findings list, the brief, the report file, and the
  fix diff. The re-reviewer verdicts each finding ADDRESSED or NOT ADDRESSED
  and flags new breakage in the fix diff only. New breakage joins the open
  findings. Out-of-scope observations go to the ledger as deferred minors.
- **After each round**, append to the ledger:
  `Step <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding summaries>; commits <a7>..<b7>)`

**The breaker.** When round 5 still leaves findings open, stop dispatching.
Adjudicate each finding yourself:

- The reviewer is wrong or the point is contestable: park it —
  `Step <N>: parked — <finding> — Ruling: <why the code stands>`.
- Real but nothing downstream builds on it: park it the same way, with a
  ruling that says it is real and deferred.
- Real and load-bearing (a later step builds on it, or it reveals a plan
  defect): rule on the smallest change that unblocks the rest, ledger it,
  and carry it into the next step's dispatch. Stop only when the defect
  leaves every path forward a guess.

Adjudicate only at the cap. Adjudicating earlier is pre-judging with a
different name. Every adjudication is a ledger entry — a silent discard is
forbidden.

**7. Complete the step.** Append to the ledger:

- `Step <N>: complete (commits <base7>..<head7>, review clean)` — or
- `Step <N>: complete (commits <base7>..<head7>, <K> parked)` after a
  tripped breaker.

Tell the user where you are ("3 of 7 done, on step 4 next").

### Model selection

Use the least powerful model that handles each role.

- **Mechanical steps** (1–2 files, clear spec, the step's text contains the
  values to use verbatim): cheap model.
- **Integration steps** (multi-file coordination, pattern matching): standard
  model.
- **Design steps** (architecture judgment, broad codebase understanding):
  most capable model.
- **Reviewers**: match the model to the diff's size, complexity, and risk.
  Scoped re-reviews of small fix diffs take a cheap model.
- **Fix-loop escalation (rounds 4–5)**: at least one tier above the
  implementer that got stuck.

Always specify the model explicitly when dispatching. An omitted model
inherits the session's model, which silently defeats this section.

### Batching

When several consecutive steps are small, independent, same-shape edits
(the same one-line fix, constant change, or field addition repeated across
files), compose one dispatch listing every file and its change. Send the
batch to a single subagent and review its diff as one unit. Reserve
one-dispatch-per-step for work that needs its own judgment, tests, or
review surface.

### Context hygiene

Pass diffs, reports, and briefs as files. Never paste them into the
dispatch prompt. Never accumulate prior-step summaries in later dispatches.
A fresh subagent needs its step, the interfaces it touches, and the global
context. Nothing else.

### Rulings

When an ambiguity blocks a subagent, decide it. The ticket, the initiative,
the ADRs, and the repo conventions are the authorities. Record every ruling
in the ledger as `Ruling: <decision> — <why> — <cost if wrong>`.

Four things stop you and require asking the user:

- An irreversible or destructive operation.
- A security-sensitive action.
- A side effect outside this worktree (a merge, a push, a publish).
- A plan so broken that every path forward is a guess.

For everything else, rule and record. A wrong ruling costs rework the user
can see and undo. A session parked on a question costs their whole day and
buys nothing.

### Principles carried into each dispatch

These apply to every implementer subagent. Include them in the dispatch
context:

- **Tests at the layer the change lives at**, not one layer up where they are
  easier to write.
- **Deviations get recorded, not hidden.** If implementing shows the plan
  step was wrong, the subagent says so in its report. The coordinator
  records it in the ledger and in the PR body at the end. Never rewrite the
  plan field to match what happened.
- **Scope discipline.** Each subagent builds its step, not its step plus the
  thing next to it. Note the neighbour, finish the step.

## 6. Review the whole branch

Per-step reviews caught issues within each step. This review catches what
they cannot see: cross-step inconsistencies, duplicated logic across steps,
conventions violated only when the full diff is visible, and the deferred
findings from the ledger.

Write the full branch diff to a file: `git diff $(git merge-base main HEAD)..HEAD`
redirected to `.colormath/sdd/<ticket-key>/branch-review.diff`. Dispatch a
code reviewer on the **most capable available model** with: the diff file,
the ticket's description and acceptance criteria, and every line from the
ledger that contains `parked` or `deferred`. The reviewer sees the whole
change and decides which deferred items must be fixed before merge.

If the review returns findings, dispatch **one** fix subagent with the
complete findings list. One fixer for all findings, not one per finding.
Then dispatch one scoped re-review of the fix diff. Adjudicate any residual
findings the same way as the step-level breaker: park with a ruling, or
rule on load-bearing findings and ledger what you decided. There is no
second fix wave. Residual load-bearing findings surface to the user in the
final report.

Before moving on, collect every ledger line that contains `Ruling:` into a
summary. This list is the only place where the decisions you made on the
user's behalf reach them. A ruling that dies with the ledger was a decision
made in secret.

## 7. Execute the QA plan against the running stack

The QA plan is a list of claims about a running system, and an item counts only
when you have watched the system agree. A passing test suite is not the QA plan
— it is one of the things the QA plan usually says to check.

Bring the stack up the way the repo does it (`make up-dev` or its equivalent),
and follow `/colormath:qa`'s recon discipline for identities and seeded data —
authorization items need the *wrong* role as well as the right one, and one
admin account proves nothing about access control.

Work every item and record what you observed: the request and response, the row
you read back, the screen state. Drive UI items through a browser if one is
reachable; if none is, mark them `⚠️` unverified and say so plainly rather than
inferring them from the code the subagents just wrote — which is the least
trustworthy possible source for whether the UI works.

Anything that fails is yours to fix now, then re-run the item. A QA plan item
that fails and gets shipped anyway is worse than one nobody ran, because the
document now says it passed.

Restore what you mutated: rows you created, config you flipped, credentials you
minted. Local state is yours to change and yours to put back.

## 8. Ship it

The ticket has been sitting in the right column since step 2, which is what
`ship` needs: it moves the ticket on from *this* column, and a ticket still in
the one behind would be moved from the wrong place.

Run the repo's full local gate mirror once (`make preflight`) so an avoidable
failure does not cost a CI round trip. Then invoke `/colormath:ship`, which
takes it the rest of the way: PR, gates, the review, a second pass over this
same QA plan against the running stack, fixes for what turns up, either an
auto-merge when the PR is genuinely clean or a hold with the reason — and the
next move on the project.

Give ship a title naming the change in the ticket's own terms, and a body that
carries what a reviewer cannot reconstruct: **the ticket key and what it asked
for**, **where the plan held and where it did not**, **the QA plan's results
including anything unverified**, and any deviation you made and why.

When ship comes back, `add_comment` on the ticket with the outcome — the PR
link, whether it merged or is held, the deviations, and the full rulings
list from step 6. That comment is how the ticket stops being a plan and
becomes a record. Leave the ticket's own fields alone: `plan` and `qa_plan`
are what was intended, and the comment is what happened.

Delete the workspace directory (`.colormath/sdd/<ticket-key>/`) — the git
history is the record now. Other tickets' directories are not yours to
touch.

## 9. Record that you ran

Abacus cannot see this happen. Nothing outside your own run knows a skill
started, so a run you do not record did not happen as far as the ticket is
concerned — and the counts worth having are the ones nobody wants: a ticket
implemented twice is a ticket whose plan did not survive contact with the code,
and the second attempt looks like the first.

`mcp__abacus__record_metric` with the ticket's `id`, `metric: "skill_invoked"`,
and `subject: "implement-ticket"` — the bare name, never the whole command,
because the plugin half is configuration and differs per project.

**Once, at the end, and only if you did the work.** Not on every turn and not
when you begin — a skill that reports each time it thinks makes the count
meaningless. The project move in step 2 is deliberately the other way round, and
the two are not in tension: a column is a claim about what is happening now, so
it is only useful said early, while a metric is a record of what happened, which
cannot be written until it has. If you were interrupted, or you sent the ticket
back to `/colormath:plan-ticket` or `/colormath:gather-requirements` without
building anything, record nothing: a run that did not happen must not leave a
row saying it did.

**The rows are append-only.** Nobody can edit or delete one, you included, so a
wrong subject or a double-record is permanent. Get it right rather than
expecting to correct it.

If there is no ticket, or the call fails, say so in your report and carry on.
The work is done either way, and a report claiming a measurement it did not
take is worse than a missing row.

## Rules

- **Execute the plan; don't rewrite it.** No re-grooming, no "improving" the
  plan silently. Where it is wrong, rule on it and ledger the ruling.
- **A ticket with no plan goes back to `/colormath:plan-ticket`.** Writing the
  plan and implementing it in the same breath means nobody ever reviewed the
  plan.
- **Move the ticket when you start, not when you finish.** The column says
  somebody is on this; said at the end it was never true while it was true. Hand
  the ticket back and you move it back.
- **Never work on the default branch**, and never merge by hand — `ship` owns
  that decision and has the gates to make it.
- **QA is executed, not asserted.** Every item gets an observation. Unverified
  is a legitimate result and gets marked; assumed is not.
- **One ticket.** Don't implement its neighbours, don't fix adjacent bugs beyond
  what the change requires, don't create tickets. Note them and move on.
- **Record what actually happened** in a ticket comment at the end,
  deviations included, and leave the planned fields as the record of intent.
- **Never dispatch implementation subagents in parallel.** Steps have
  dependencies. One at a time, in order.
- **Never fix findings yourself.** Your context stays clean for coordination.
  Resume the implementer or dispatch a fresh one. Controller fixes skip
  review.
- **Every adjudication is a ledger entry.** A silent discard is forbidden.
  Adjudicate only at the cap (round 5), never earlier.
- **The ledger is the recovery map.** After context compaction, trust the
  ledger and `git log` over your own recollection. A run you do not record
  in the ledger did not happen.
