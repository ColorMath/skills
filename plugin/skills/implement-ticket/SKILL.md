---
name: implement-ticket
description: Take a planned ticket all the way to a shipped PR — check its plan still matches the code, ask only what genuinely blocks, build it at the layer the plan names, execute its QA plan against the running stack, then hand off to /colormath:ship. Use this when someone says to implement, build, do, or work a ticket that has already been groomed, or names a ticket key and says "go". Not for grooming (that's /colormath:gather-requirements, then /colormath:plan-ticket) and not for a defect report (that's /colormath:bugfix).
argument-hint: [ticket key, e.g. CM-00012]
allowed-tools: Agent Workflow Bash Read Edit Write Grep Glob Skill AskUserQuestion mcp__abacus__get_ticket mcp__abacus__record_metric mcp__abacus__add_comment mcp__abacus__get_project mcp__abacus__move_ticket mcp__abacus__list_projects mcp__abacus__list_tickets
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

## 5. Build it with a workflow

Branch first — `feat/<ticket-key-slug>` or the repo's own convention — never
the default branch.

Build a workflow script from the plan steps and run it with the Workflow
tool. The workflow handles the implementation, review, and fix loop for
each step, with a live progress bar. You do not dispatch subagents yourself.

### Write the step briefs

For each plan step, write a brief file to
`.colormath/sdd/<ticket-key>/step-<N>-brief.md`. The brief contains:

- The step's full text from the plan, including its Consumes/Produces
  interfaces.
- One line on where this step fits ("step 3 of 7, after the migration,
  before the API route").
- Global context: what the ticket is for, acceptance criteria, and
  conventions.
- The no-subagents contract: the implementer never dispatches subagents.

Each brief is the subagent's requirements. It does not read the whole plan.

### Decide batching and models

Before building the script, decide which steps to batch and which model
each step gets.

**Batching:** consecutive steps that modify the same file and are small,
same-shape edits go into one phase. Each batch becomes one implementer
agent call in the script.

**Model selection per step:**

- **Mechanical** (1–2 files, clear spec): `sonnet`
- **Integration** (multi-file, pattern matching): `sonnet`
- **Design** (architecture judgment, broad codebase): `opus`
- **Reviewers**: `sonnet` for most diffs, `opus` for complex or risky ones
- **Fix-loop escalation**: one tier above the implementer that got stuck
- **Branch review**: `opus` (most capable)

### Build and run the workflow script

Build a JavaScript workflow script and pass it to the Workflow tool. The
script follows this structure:

```javascript
export const meta = {
  name: 'implement-<ticket-key>',
  description: 'Implement <ticket title>',
  phases: [
    // one entry per step (or batch), plus review
    { title: 'Step 1-3: <title>' },
    { title: 'Review 1-3' },
    { title: 'Step 4: <title>' },
    { title: 'Review 4' },
    // ... one pair per step or batch
    { title: 'Branch review' },
  ],
}

// Each step: implement → review → fix loop if needed
const STEPS = [
  // generated from plan steps and briefs
  {
    phase: 'Step 1-3: <title>',
    reviewPhase: 'Review 1-3',
    briefPath: '.colormath/sdd/<key>/step-1-2-3-brief.md',
    model: 'sonnet',
  },
  // ...
]

for (const step of STEPS) {
  phase(step.phase)
  const impl = await agent(
    `Read ${step.briefPath} — it is your requirements. Implement it, ` +
    `run the tests, commit. Do not dispatch subagents.`,
    { phase: step.phase, model: step.model }
  )

  phase(step.reviewPhase)
  const review = await agent(
    `Review the most recent commits against ${step.briefPath}. ` +
    `Check spec compliance and code quality. Report findings.`,
    { phase: step.reviewPhase, model: 'sonnet' }
  )

  // fix loop: up to 5 rounds
  let findings = review?.findings || []
  let round = 0
  while (findings.length > 0 && round < 5) {
    round++
    const fixModel = round >= 4 ? 'opus' : step.model
    await agent(
      `Fix these findings: ${JSON.stringify(findings)}. ` +
      `Read ${step.briefPath} for context.`,
      { phase: step.phase, model: fixModel }
    )
    const reReview = await agent(
      `Re-review: are these findings addressed? ${JSON.stringify(findings)}`,
      { phase: step.reviewPhase, model: 'sonnet' }
    )
    findings = reReview?.open || []
  }
  if (findings.length > 0) {
    log(`Step capped at 5 rounds with ${findings.length} open findings`)
  }
}

// Branch review
phase('Branch review')
const branchReview = await agent(
  'Review the full branch diff for cross-step issues, duplicated ' +
  'logic, and convention violations. Report findings.',
  { phase: 'Branch review', model: 'opus' }
)
if (branchReview?.findings?.length) {
  await agent(
    `Fix all branch-review findings: ${JSON.stringify(branchReview.findings)}`,
    { phase: 'Branch review', model: 'opus' }
  )
}
return { findings: branchReview?.findings || [] }
```

**This is a template.** Generate the actual script from the plan steps,
briefs, batching decisions, and model assignments. The structure stays the
same: implement → review → fix loop per step, then branch review.

Pass the script to the Workflow tool via the `script` parameter. Do not
write it to a file first. The Workflow tool returns when all phases are
complete.

### After the workflow

Read the workflow result. Collect any open findings or rulings. These go
into the ticket comment and PR body at the end.

## 6. Execute the QA plan against the running stack

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

## 7. Ship it

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
list from the workflow result. That comment is how the ticket stops being a plan and
becomes a record. Leave the ticket's own fields alone: `plan` and `qa_plan`
are what was intended, and the comment is what happened.

Delete the workspace directory (`.colormath/sdd/<ticket-key>/`) — the git
history is the record now. Other tickets' directories are not yours to
touch.

## 8. Record that you ran

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
- **The workflow builds the code; you do not.** Do not write code outside
  the workflow. Do not dispatch implementation subagents yourself. The
  Workflow tool handles sequencing, progress, and resume.
- **Open findings from the workflow go into the ticket comment and PR body.**
  Do not silently discard them.
