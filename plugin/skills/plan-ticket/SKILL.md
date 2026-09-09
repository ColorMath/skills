---
name: plan-ticket
description: Turn a ticket whose requirements are settled into one somebody could start on Monday — read it, investigate the code it touches at file-and-line level, settle the few implementation forks the requirements left open, then write back a file-anchored implementation plan and an executable QA plan. Use this whenever someone wants a ticket planned, made ready, starred, estimated, or "taken from a description to something I can pick up" — or names a ticket key (CM-00001) and asks how it would be built. Not for establishing what is being asked for (that's /colormath:gather-requirements), not for finding unknown problems in a feature (that's /colormath:qa), and not for implementing it — the planned ticket is the deliverable.
argument-hint: [ticket key, e.g. CM-00001 — or enough of the title to find it]
allowed-tools: Bash Read Grep Glob AskUserQuestion mcp__abacus__get_ticket mcp__abacus__update_ticket mcp__abacus__add_comment mcp__abacus__list_boards mcp__abacus__list_tickets mcp__abacus__list_members
---

Plan the ticket named in "$ARGUMENTS" until someone else could pick it up cold
and build it.

The requirements question — *what is being asked for, and why* — has already
been answered by `/colormath:gather-requirements`, or by a human who wrote a
description that stands on its own. **Your job is the other half: how it gets
built, and how anyone knows it worked.** Two fields, and the ticket is shown as
ready only when it has both.

The failure mode this skill exists to prevent is **the plan of generic steps**:
"update the relevant service", "add tests", "verify it works". It names
nothing, could have been written without opening the repo, and cannot be wrong
in a way anybody can catch. A plan is useful in proportion to how specifically
it can be contradicted.

So the spine is **read → check it's ready to plan → investigate → settle the
forks → draft → confirm → write.** Anchor every step in a real file, at a real
line where you can.

Quote the ticket by its **key** (`CM-00001`) throughout — that's what people
call it by, never the UUID.

## 1. Read the ticket, and check this is the right skill for it

Call `mcp__abacus__get_ticket`. It takes the key directly, and case and
zero-padding don't matter, so `cm-1` resolves. If "$ARGUMENTS" is a title
fragment rather than a key, find it with `list_boards` then `list_tickets` and
confirm which one you landed on.

**Read `type` first, because two of the four stop here:**

- **`feature` or `bug`** — carry on. These are the types that carry plans.
- **`initiative`** — wrong altitude. An initiative is not implemented directly;
  its plans belong to the tickets cut from it. If it is still `designing`, that
  is `/colormath:gather-requirements`. If it is `building`, planning its
  children in order is `/colormath:plan-initiative`. Say which and stop.
- **`task`** — a task is work that isn't code, and it carries **no
  implementation plan and no QA plan by design**: `update_ticket` refuses to
  write either, and a task is never "ready". Say so and stop. Its description
  is the whole of its grooming, and `/colormath:gather-requirements` owns that.

Then read all of it: description, existing plan, existing QA plan, **every
comment**, swimlane, assignee, release, and the initiative it sits under.
Comments are where decisions already made go to hide, and a plan that
contradicts a decision recorded in the ticket's own thread is an avoidable
embarrassment.

**Then check the requirements are actually settled**, because planning against
a description that isn't is how a plan comes out fluent and wrong. The bar is
low but it is a real bar: can you say, from the ticket alone, what problem this
solves, what "done" looks like as something observable, and what is
deliberately out of scope?

If you can't, **say so and hand back to `/colormath:gather-requirements`**
rather than quietly inventing the missing half. That is the whole point of the
two skills being two. If the gap is narrow — one ambiguity, one missing
acceptance criterion — you may settle it in step 3 instead and write it into
the plan as a stated assumption; use that judgement, but name the choice you
made in the final report either way.

If the ticket already has a plan or a QA plan, you are **revising, not
authoring**. Read the prior text as evidence of intent, keep what's still true,
and note anything you're contradicting so you can raise it rather than quietly
deleting someone's thinking. A plan that has gone stale because the code moved
under it is the common case and worth saying out loud.

## 2. Investigate the code, at the altitude gathering deliberately avoided

This is where most of the time should go. `gather-requirements` named the
modules; you name the files, the functions and the lines.

Go read what the ticket would touch: the routes, services, models, templates,
jobs, migrations and config. You are answering, for yourself:

- **Which files actually change**, in what order, and roughly how much.
- **Which layer the change belongs at**, and why there rather than the place
  the symptom appears. The repo's architecture notes and ADRs decide this, not
  convenience — a fix in a route that belonged in a service passes review and
  rots.
- **What else reaches this code.** Every other caller of the function you are
  about to change is regression surface, and step 6 is where they get checked.
- **What the existing tests already cover**, so the QA plan doesn't duplicate
  the suite, and so you can see what the suite is blind to.
- **What has moved since the description was written.** Files get renamed,
  adjacent changes land, assumptions expire. A description six weeks old is
  evidence, not ground truth.

Then hunt specifically for **what the diff won't contain**. Work whose code
change looks like a one-line edit is a signal to keep digging: a migration that
has to land in a particular order, a credential someone has to issue, a
backfill for rows written under the old behavior, a deploy that must reach two
services and not one, a config change in an environment you can't see. Miss
that and the plan is a confident lie about the effort, and whoever picks the
ticket up discovers it at the worst moment.

Distinguish, out loud and in the write-up, **what you verified** from **what
you inferred**.

## 3. Settle the forks — and only the forks

You should have very few questions. The requirements interview already
happened, and re-asking it is both annoying and a sign you skipped step 1's
check. What is left is the implementation choices the requirements genuinely
did not decide, and only those where **two reasonable builds differ in a way
someone would notice later**:

- Where new state lives, and whether it is derived or stored.
- What happens to data already written under the old behavior — the backfill,
  or the deliberate decision not to.
- Ordering: what has to ship first, and whether it can ship alone.
- An invariant the plan would have to bend, with the cost of each side. Never
  bend one silently.
- A dependency outside the repo that has to be arranged by a person.

**One round, four questions at most.** Use `AskUserQuestion` with concrete
options, recommendation first, and say why. If you would write the same plan
either way, don't ask — take the conventional default and write it into the
plan as a stated assumption, where it can be contradicted cheaply. If nothing
is genuinely open, skip this step and say so.

## 4. Write an implementation plan someone could follow

Ordered steps, each naming **real paths** — `services/billing.py:212`, not
"the billing service". A step that names no file is a wish, and the reader
can't tell a wrong plan from a vague one.

Lead with **prerequisites and blockers** when there are any, because they
decide whether the work can start at all, and they're what step 2 was hunting
for.

Then, for the change itself: the files and the order, the *layer* the change
belongs at and why, any migration or data implication, and the rollout sequence
when deploy order matters. Include **what explicitly does not need to change**
— it bounds the diff against scope creep, and it's the visible proof that you
actually looked.

Close with **open questions** — everything unresolved, stated plainly rather
than papered over. A plan that admits two unknowns is more useful than one that
silently guesses at them. Anything you assumed in step 3 goes here too, as an
assumption.

Size it honestly. If the work turned out to be bigger than the description
implies, say so here rather than letting someone discover it mid-build — and
if it turned out to be *much* bigger, that is a finding about the requirements
and belongs in your report as well as in the plan.

## 5. Write a QA plan that someone can actually execute

This is the section most tickets never get, and the reason defects ship. The
test is mechanical: **could a person execute each item without asking you what
you meant?** Each needs a surface, an identity, an input, and an expected
observable. "Verify it works" fails that test.

Work these dimensions and drop the ones that don't apply, rather than padding:

- **The happy path**, at the privilege tier that actually matters.
- **Authorization and tenancy** — the wrong role, the neighboring tenant, the
  logged-out visitor. One admin account proves nothing about access control.
- **The failure and edge cases this change introduces** — bad input, absent
  optional data, the boundary values, the second concurrent attempt.
- **Regression surface** — what *else* reaches this code. Step 2 found the
  other callers; this is where they get checked.
- **Data written under the old behavior.** Existing rows rarely match what the
  new code assumes, and local seed data is pristine and therefore hides it.
- **Accessibility**, when there's UI: keyboard reachability, labels and
  semantics, announcement of state changes, contrast.
- **Post-deploy verification**, when the change only manifests in a deployed
  environment — name the environment, the check, and who can run it.

Then separate **what automated tests will cover** from **what needs hands**,
and name the repo's gates the change implicates — diff coverage on new logic,
a11y on templates, a dependency or secrets scan on new config. A QA plan that
duplicates the test suite wastes the tester; one that assumes the suite covers
the interesting case wastes the release.

Write it knowing **`/colormath:ship` will execute it verbatim** against a
running stack, and will not edit it. An item that cannot be driven from a
terminal or a browser is an item that will come back marked unverified.

## 6. Show it, confirm, then write it back

Show the drafted plans in chat **before** writing anything, and ask for a
go-ahead. Call out explicitly, at that moment, if you are **overwriting plan or
QA-plan text you didn't write** — say what's being replaced so the loss is a
decision rather than an accident.

On approval, `mcp__abacus__update_ticket` with **two fields**: `plan` (the
implementation plan) and `qa_plan`. They are distinct fields, not sections of
one — a ticket is shown as ready only once it has **both**, so folding QA into
the plan field leaves the ticket looking unready no matter how good the writing
is. Both are markdown, stored and shown verbatim.

**Do not write `description`.** Pass only the two plan fields; anything you
omit keeps its current value. If the investigation showed the description is
wrong or incomplete, say so in your report and recommend
`/colormath:gather-requirements` — rewriting it here would silently redefine
the ticket under the person who scoped it.

Where the planning produced a decision worth preserving as a record — a
rejected approach, the reasoning behind an ordering constraint — `add_comment`
is the right home for it, since the plan should read as the current intent
rather than its history.

Finish by telling the user, in chat: the ticket key, that it is now ready, what
you verified against the code versus assumed, the open questions that survived,
and that `/colormath:implement-ticket` (or `/colormath:bugfix`, for a bug) is
what takes it from here. Nothing here can delete a ticket — say so plainly if
you're asked to.

## Rules

- **Check the requirements are settled before planning against them.** A plan
  built on a description that doesn't say what "done" is will be fluent and
  wrong. Hand back to `/colormath:gather-requirements` rather than inventing
  the missing half.
- **Never write `description`.** It is the other skill's field, and the person
  who scoped the ticket owns it.
- **Every plan step names a real file.** No step that could have been written
  without opening the repo.
- **Write both fields or say why not.** A ticket with a plan and no QA plan is
  not ready and does not look ready, which is worse than one that is obviously
  neither.
- **Ask only what changes the plan**, one round, four questions at most. The
  requirements interview already happened.
- **Never invent an answer the user didn't give.** Unresolved goes into the
  ticket as a stated open question or a stated assumption — visibly, where it
  can be contradicted — never silently resolved in your favor.
- **Don't implement the ticket.** No branches, no code edits, no PRs. The
  planned ticket is the deliverable; `/colormath:implement-ticket`,
  `/colormath:bugfix` and `/colormath:ship` take it from there as separate,
  deliberate acts.
- **Plan this ticket only.** Don't create, split, move, reassign or re-type
  tickets as a side effect — if the work is really several tickets, recommend
  the split and let the user call it.
- **Confirm before writing**, and never overwrite someone else's plan without
  saying that's what you're doing.
- **Say when a ticket shouldn't be built.** If the investigation shows it's
  already built, already rejected by a recorded decision, or solves a problem
  that no longer exists, that finding *is* the deliverable — report it instead
  of dutifully producing a plan for work nobody needs.
