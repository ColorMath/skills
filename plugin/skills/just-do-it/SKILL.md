---
name: just-do-it
description: Take a small, well-described ticket from Abacus straight to a shipped PR in one session, without the separate gather-requirements and plan-ticket steps. Use this when someone says "just do it", "knock this out", "this is a quick one", or names a ticket key for work they have already spelled out and know is small — a migration, an endpoint, a simple bug fix, a design tweak, a config change. Not for initiatives, not for tickets with no description, and not for work whose scope is unclear.
argument-hint: [ticket key, e.g. CM-00012]
allowed-tools: Agent Bash Read Edit Write Grep Glob Skill AskUserQuestion ToolSearch mcp__abacus__get_ticket mcp__abacus__record_metric mcp__abacus__add_comment mcp__abacus__get_project mcp__abacus__move_ticket mcp__abacus__list_projects mcp__abacus__list_tickets mcp__abacus__link_pull_request mcp__abacus__update_ticket
---

Read the ticket in "$ARGUMENTS", decide whether it is a good fit for one shot,
build it, and ship it.

This skill exists because the normal flow — gather-requirements, plan-ticket,
implement-ticket, ship — is the right weight for most work and too much
ceremony for the rest. A ticket that says "add a `deleted_at` column to
`organizations`" does not need three separate skills to tell it what it already
knows. This skill is the fast path for work the user has already thought
through.

The risk is that "small" is a feeling, not a measurement, and a ticket that
looked small in the title can hide a migration on a hot table, a permission
model nobody mentioned, or a scope that only becomes clear at the third file.
So the first job here is an honest fitness check, and the second is building
it the way a good agent would if you had simply typed the prompt.

## 1. Read the ticket and check fitness

Call `mcp__abacus__get_ticket`. It takes the key directly; case and padding
do not matter. If "$ARGUMENTS" is a title fragment, resolve it with
`list_projects` / `list_tickets` and confirm which one you landed on.

Read all of it: description, every comment, type, swimlane, assignee, the
initiative it sits under if it has one.

**Then decide whether this ticket belongs here.** Two things rule it out:

- **It is an initiative.** Always out. Its children are what get built.
- **It is a task.** A task carries no code. Say so and stop.

If neither applies, assess complexity. A ticket with a thin or empty
description is fine here — the user has already thought it through and the
title plus context may be all that is needed. Read the code the ticket touches:
the modules, services, models, templates, and tests that would change. You are
answering one question: **can a single agent, in one session, build this and
be confident it is correct?**

Signs it is a good fit:

- One or two files change.
- The change follows an existing pattern in the codebase.
- The acceptance criteria are obvious from the description.
- No new table, no new permission, no new background job.

Signs it is not:

- Three or more modules with non-trivial changes.
- A new data model or a migration on a table with live traffic.
- The description leaves real design decisions open.
- It collides with work in flight.

**Present your assessment.** Tell the user what you found and whether you
think this is a good fit. If you think it is not, recommend the normal flow
and name which skill to start with. Give them the choice either way:
`AskUserQuestion` with "Go ahead, build it" (if you think it fits) or
"Use the normal flow" as options. Let the user override your recommendation.

## 2. Move the ticket into the implementing column

This works the same way as `implement-ticket` step 2. Call
`mcp__abacus__get_project` with the ticket's `project_id`. Find the
`exit_commands` entry whose `skill` is `implement-ticket` and
`mcp__abacus__move_ticket` with that entry's `leads_to` as the `swimlane_id`,
and `position: 0`.

If no column names `implement-ticket`, or the ticket is not in a column, or the
move fails: say so and carry on. The work is not conditional on the project
tracking it.

**Keep the ticket's current `swimlane_id`** so you can put it back if you
bail out.

## 3. Build it

Branch first: `feat/<ticket-key-slug>` or the repo's own convention. Never the
default branch.

Read the codebase the way any good agent would. Find the existing patterns,
understand the conventions (`AGENTS.md` / `CLAUDE.md`, ADRs, rules files), and
build the change. Run the tests after each meaningful step.

There is no written plan to follow. The ticket description is your
specification, and the comments carry any decisions made after it was filed.
Build what they say, at the altitude they say it.

If you discover mid-build that this is bigger than it looked — a new model is
needed, an invariant has to bend, a design decision is genuinely open — stop.
Tell the user what you found and recommend handing it to the normal flow. Move
the ticket back to the column you saved in step 2 if you bail out.

## 4. QA it

Bring the stack up the way the repo does it. Work through the acceptance
criteria from the ticket description against the running system. Use browser
tools for UI items (find them via ToolSearch), curl for API items, the database
client for data items.

Fix what fails, then re-check it. If something cannot be verified with the
tools available, say so plainly and mark it unverified.

Leave the stack running for ship.

## 5. Ship it

Run `make preflight` (or the repo's equivalent) to catch avoidable failures
before CI.

Invoke `/colormath:ship`. It handles the PR, gates, review, a second QA pass,
fixes, the merge decision, and the project move.

Give ship a title naming the change, and a body with: the ticket key, what it
asked for, what you built, and anything unverified from step 4.

When ship comes back, `add_comment` on the ticket with the outcome: the PR
link, whether it merged or is held, and anything notable.

## 6. Record that you ran

`mcp__abacus__record_metric` with the ticket's `id`, `metric: "skill_invoked"`,
and `subject: "just-do-it"`.

**Once, at the end, and only if you did the work.** If you bailed out in step 1
or mid-build, record nothing.

**The rows are append-only.** A wrong subject or a double-record is permanent.

If there is no ticket, or the call fails, say so and carry on.

## Rules

- **The ticket is the spec.** The description, the title, and the comments are
  what you build from. Do not re-groom it, do not rewrite it, do not add a plan
  to the ticket.
- **Stop when it gets big.** Discovering complexity mid-build is normal and is
  the right time to hand off. A one-shot skill that quietly becomes a
  three-hour session has failed at its job.
- **Never work on the default branch.** Branch first, always.
- **QA is executed, not asserted.** Every acceptance criterion gets an
  observation against the running system.
- **One ticket.** Do not fix adjacent bugs, do not create tickets, do not
  implement neighbours. Note them and move on.
- **Ship handles the PR.** Do not merge by hand. `/colormath:ship` owns the
  gates, the review, and the merge decision.
