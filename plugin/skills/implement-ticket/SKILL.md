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
  produces. Verify that what step N says it produces is what step M says
  it consumes — the same function names, the same types, the same data
  shapes. Follow the `Depends on:` annotations, not just adjacent pairs:
  step 5 may consume from step 2, not step 4. A mismatch here means two
  subagents will build to different contracts.
- **Are the dependency annotations consistent?** For each step, verify that
  its `Depends on:` field matches its `Consumes` field. If a step consumes
  something from step M's Produces but does not list step M in Depends on,
  the dependency graph is wrong and the execution strategy in step 5a will
  be wrong. Flag it and correct the annotation in the ledger.
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

## 5. Choose the execution strategy and assign models

Branch first — `feat/<ticket-key-slug>` or the repo's own convention — never
the default branch.

### Write the step briefs

For each plan step, write a brief file to
`.colormath/sdd/<ticket-key>/step-<N>-brief.md`. The brief contains:

- The step's full text from the plan, including its Consumes/Produces
  interfaces.
- One line on where this step fits ("step 3 of 7, after the migration,
  before the API route").
- Global context: what the ticket is for, acceptance criteria, and
  conventions.
- The step's Reuse, Pattern, and Files fields from the plan, which tell the
  implementer what existing code to extend and which conventions to follow.
- The no-subagents contract: the implementer never dispatches subagents.
- The scan results from step 3: if the ledger contains rulings that affect
  this step, include them in the brief so the implementer builds within
  those decisions.

Each brief is the subagent's requirements. It does not read the whole plan.

### 5a. Choose execution strategy

Read the plan's `Depends on:` annotations and the dependency graph summary.
Choose one of four strategies:

1. **Inline** — the main agent implements directly, no subagents. When:
   1-2 steps, under ~20 lines changed, purely mechanical. The orchestration
   overhead exceeds the work itself. This is the escape hatch, not the
   default.
2. **Sequential subagents** — dispatch one Agent per step, wait for each
   before the next. When: steps have real dependencies (each consumes the
   prior step's output) and no parallelizable groups. Keeps the main
   agent's context clean for orchestration, QA, and shipping.
3. **Parallel workflow** — launch a Workflow that uses `parallel()` or
   `pipeline()` for independent step groups. When: 2+ steps can run
   concurrently per the dependency graph. Steps within a parallel group
   use worktree isolation if they touch the same files. A workflow script
   that is just a sequential for-loop of `await agent()` calls is never the
   right answer; use sequential subagents instead.
4. **Hybrid** — sequential subagents for implementation, then a parallel
   workflow for the review phase (fan out independent review dimensions
   concurrently). When: steps are sequential but the review benefits from
   multiple independent perspectives.

The dependency graph is the input. If no steps are independent, parallel
adds orchestration cost with no concurrency benefit. If all steps are
independent, sequential wastes the parallelism the graph offers.

### 5b. Assign models per step

For each step (and its reviewer if applicable), assign a model tier:

- **Sonnet** — mechanical edits, clear spec, pattern-following (1-2 files,
  existing pattern named in plan).
- **Opus** — design judgment, broad codebase reasoning, ambiguous
  requirements, or novel patterns.
- **Haiku** — trivial single-file edits (config changes, adding one dict
  entry).

For reviewers: match the implementer's tier unless the diff is unusually
risky, then bump one tier. For the branch review: always Opus.

Fix-loop escalation: one tier above the implementer that got stuck.

### 5c. Present the execution plan

Show both decisions together in one `AskUserQuestion` with the recommended
option first. Include the strategy, the dependency reasoning, and a table
of model assignments. Example:

> 6 steps, all sequential (no parallelizable groups). Recommend:
> Sequential subagents.
>
> | Step | Model | Rationale |
> |------|-------|-----------|
> | 1-3: Model + config + serializer | Sonnet | Mechanical, follows existing pattern |
> | 4: Routes | Sonnet | Follows admin_sponsored_career_images.py |
> | 5: Template | Opus | Design judgment, custom wrapper |
> | 6: Tests | Sonnet | Follows existing test patterns |
> | Branch review | Opus | Cross-step reasoning |

The user sees the full execution plan (strategy + models) before any code
runs and can override either.

## 6. Execute the chosen strategy

Run the strategy the user approved. Each strategy shares the same
implement-review-fix loop per step, and all end with a branch review. The
difference is orchestration.

### Shared: the review and fix loop

Every step, regardless of strategy, follows this cycle:

1. **Implement** — the agent reads its brief and builds.
2. **Review** — a reviewer checks spec compliance and code quality.
3. **Fix loop** — up to 5 rounds. Non-minor findings go back to the
   implementer. On round 4+, escalate the model one tier. If findings
   remain after 5 rounds, cap and record them.

The branch review at the end is always Opus, always runs, and always
checks cross-step issues, duplicated logic, and convention violations.

### Shared schemas

All strategies use these schemas for review structured output:

```javascript
const REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    verdict: { type: 'string', enum: ['pass', 'fail'] },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          summary: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'important', 'minor'] },
          file: { type: 'string' },
        },
        required: ['summary', 'severity'],
      },
    },
  },
  required: ['verdict', 'findings'],
}

const RE_REVIEW_SCHEMA = {
  type: 'object',
  properties: {
    open: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          summary: { type: 'string' },
          severity: { type: 'string', enum: ['critical', 'important', 'minor'] },
          addressed: { type: 'boolean' },
        },
        required: ['summary', 'severity', 'addressed'],
      },
    },
  },
  required: ['open'],
}
```

### Strategy 1: Inline

Implement each step yourself, in order. After each step, run the tests.
When all steps are done, do the branch review by reading the full diff
yourself. No subagents, no workflow.

This is for 1-2 steps where dispatching an agent costs more than doing the
work.

### Strategy 2: Sequential subagents

Dispatch one Agent per step, wait for it to complete, then dispatch the
next. Each agent reads its brief, implements, runs tests, and commits.
After each agent, dispatch a reviewer agent. Run the fix loop if needed.

After all steps, dispatch the branch review agent (Opus).

```
for each step:
  Agent(implement, model=step.model)  →  wait
  Agent(review, model=reviewer.model) →  wait
  fix loop if needed
Agent(branch review, model=opus)
```

### Strategy 3: Parallel workflow

Build a Workflow script that uses `parallel()` for independent step groups
and sequential `await` for dependent ones. The dependency graph from the
plan dictates the structure.

Steps within a parallel group that touch the same files use
`isolation: "worktree"` to avoid conflicts. Steps that touch disjoint
files run in the same worktree.

Each step still gets the full implement-review-fix loop. Use `pipeline()`
when one group feeds the next:

```javascript
// Example: steps 1,2 are independent; step 3 depends on both
const [r1, r2] = await parallel([
  () => implementAndReview(step1),
  () => implementAndReview(step2),
])
const r3 = await implementAndReview(step3)
```

A workflow script that is just a sequential for-loop of `await agent()`
calls is never the right answer. If the dependency graph is fully
sequential, use strategy 2 instead.

Pass the script to the Workflow tool via the `script` parameter. Do not
write it to a file first.

### Strategy 4: Hybrid

Dispatch sequential subagents for implementation (strategy 2), then launch
a parallel Workflow for the review phase. The workflow fans out independent
review dimensions concurrently (e.g., spec compliance, security, and
performance as parallel reviewers).

Use this when steps are sequential but the review benefits from multiple
independent perspectives that do not need to see each other's output.

### After execution

All strategies produce the same output: `{ branchFindings, cappedFindings }`.

- `branchFindings` — issues from the whole-branch review.
- `cappedFindings` — per-step issues that hit the 5-round fix cap.

For **inline** (strategy 1), you are the implementer and reviewer. Collect
your own branch-review findings into `branchFindings` and any capped
per-step findings into `cappedFindings` so the downstream reporting (ticket
comment, PR body) works the same way regardless of strategy.

For **sequential subagents** (strategy 2), collect the structured output
from each reviewer agent into the same shape as the workflow returns.

Both lists go into the ticket comment and PR body at the end. If either
list is non-empty, report each finding to the user before moving to QA.

If a **workflow** was interrupted (machine sleep, context limit, or user
interruption), re-invoke the Workflow tool with `resumeFromRunId` set to
the prior run's ID. Completed `agent()` calls with unchanged prompts return
cached results. Only the interrupted step and everything after it re-runs.
This applies only to strategies 3 and 4.

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
link, whether it merged or is held, the deviations, the `branchFindings`
and `cappedFindings` from the workflow result, and any rulings recorded in
the ledger (`.colormath/sdd/<ticket-key>/progress.md`). Extract the rulings
from the ledger before deleting the workspace. That comment is how the
ticket stops being a plan and becomes a record. Leave the ticket's own
fields alone: `plan` and `qa_plan` are what was intended, and the comment
is what happened.

Delete the workspace directory (`.colormath/sdd/<ticket-key>/`) after
extracting the rulings. The git history is the record now. Other tickets'
directories are not yours to touch.

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
- **The approved strategy builds the code.** For inline, you implement
  directly. For all other strategies, subagents or the Workflow tool do the
  building. Do not mix strategies or dispatch agents outside the approved
  plan.
- **Present the execution plan before any code runs.** The user sees the
  strategy, the dependency reasoning, and the model assignments, and can
  override either.
- **Open findings go into the ticket comment and PR body.** Do not silently
  discard them.
