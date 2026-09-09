---
name: gather-requirements
description: Establish what a ticket or an initiative actually asks for — read it, investigate the code and the architecture it lands in, interview the person who filed it until the picture is complete, then write back a description that stands on its own, and for an initiative, feature definitions someone could pick up. Use this whenever someone wants a ticket or initiative fleshed out, scoped, designed, "made real", or checked before work starts — or names a key and asks what it would actually take. Stops at the requirements: implementation and QA plans belong to /colormath:plan-ticket, and this is the layer above.
argument-hint: [ticket or initiative key, e.g. CM-00001 — or enough of the title to find it]
allowed-tools: Bash Read Grep Glob AskUserQuestion mcp__abacus__get_ticket mcp__abacus__update_ticket mcp__abacus__add_comment mcp__abacus__add_feature mcp__abacus__update_feature mcp__abacus__move_feature mcp__abacus__get_board mcp__abacus__move_ticket mcp__abacus__list_boards mcp__abacus__list_tickets mcp__abacus__list_members
---

Establish what the work named in "$ARGUMENTS" actually asks for, until someone
else could pick it up cold and know what they were being asked to build.

A ticket is **a reminder, not a specification**, and an initiative is **a
direction, not a design**. Both were written by someone who had the whole
context in their head and wrote down only the trigger — a title, maybe a
sentence, maybe a handful of feature lines. Everything that made it obvious to
them at the time is missing, including, often, the reason it matters.

Two failure modes follow from that shape, and this skill exists to prevent
both. The first is **fluent restatement**: expanding the title into three
paragraphs of confident prose that add words and no information, none of it
checked against the codebase. It reads like refinement and is worth nothing,
because no assumption in it was ever tested. The second is **interrogation**:
dumping a dozen open-ended questions on the person who filed it, which is
slower for them than writing it properly themselves.

The cure for both is the same, and it is the spine of this skill:
**read → investigate → interview → draft → confirm → write.** Investigate
*before* you ask, so the questions are concrete and few.

**Stop at the requirements.** No file-by-file steps, no function signatures, no
DDL, no test lists. If you catch yourself writing `services/billing.py:212`,
you have dropped an altitude — that is `/colormath:plan-ticket`'s job, done
later, per ticket. Naming a *module* as the home for something is the right
level here; naming a line is not.

Quote the work by its **key** (`CM-00001`) throughout — that's what people call
it by, never the UUID.

## 1. Read it, and work out which of the two you have

Call `mcp__abacus__get_ticket`. It takes the key directly, and case and
zero-padding don't matter, so `cm-1` resolves. If "$ARGUMENTS" is a title
fragment rather than a key, find it with `list_boards` then `list_tickets` and
confirm which one you landed on before doing anything else.

**Read `type`, because it decides what the deliverable is:**

- **`initiative`** — the deliverable is the description **and the feature
  definitions**. Read `initiative_status` too:
  - `designing` — the normal case. The features are editable; carry on.
  - `building` — **the design is closed.** Every feature write is refused by
    the server, and that is deliberate: the list is the record of what was
    agreed and the tickets have already been cut from it. Say so plainly rather
    than discovering it at the write step. You may still refine the
    initiative's own **description** if the user asks — offer that, name it as
    the only thing you can change, and get an explicit yes before writing.
    Never propose "just start a fresh initiative to get around the lock" as
    though it were free; the tickets already cut are the reason it is locked.
- **`feature` or `bug`** — the deliverable is the description. The plans come
  later, from `/colormath:plan-ticket`.
- **`task`** — the deliverable is the description, and that is *all* it can
  ever be: a task carries no implementation plan and no QA plan by design, and
  `update_ticket` refuses to write one. So this skill is the whole of grooming
  for a task. Don't hand it on to `plan-ticket` afterwards; there is nothing
  there for it to do.

Then read all of it, and mean it: description, **every comment**, swimlane,
assignee, release, the initiative it sits under, and — when it *is* an
initiative — **every feature definition** in order plus the tickets already
filed under it. `get_ticket` is the only place an initiative's children are
listed; the board tools hide them. Comments are where decisions already made go
to hide, and writing requirements that contradict a decision recorded in the
ticket's own thread is an avoidable embarrassment.

If it already has a description or features, you are **revising, not
authoring**. Read the prior text as evidence of intent, keep what is still
true, and note anything you are contradicting so you can raise it rather than
quietly deleting someone's thinking.

## 2. Investigate before you ask anything

This is the step that separates gathered requirements from padded ones, and it
is where most of the time should go. You are building the picture the filer
assumed everyone had.

**Start with the written decisions.** `AGENTS.md` / `CLAUDE.md`, the ADRs in
`docs/adr/`, the rules files. These state the invariants the work must live
inside — layering, tenancy scoping, ordering rules, audit obligations,
authorization defaults, naming. Something that violates one of these is the
single most valuable thing to catch, and you catch it here or not at all.

**Then the code it lands in.** Routes, services, models, templates, jobs,
migrations, config. You are answering, for yourself, questions the filer
shouldn't have to:

- **Does it already exist?** Fully, partially, behind a flag, or built and then
  deliberately removed. Something already shipped is the most useful finding
  you can bring back.
- **Where does it go?** Which layer owns it, which existing service grows a
  method, which needs to be created. Name real modules.
- **What does it force?** A new table, a migration, a new column on a hot
  table, a new event type, a new permission, a background job, a third-party
  dependency, a deploy-ordering constraint. These are what make work bigger
  than it looks, and finding them now matters because they change what is being
  asked for, not just how it gets built.
- **What does it collide with?** Work in flight, an adjacent subsystem that
  owns the same data, an invariant that would have to bend. Bending an
  invariant is sometimes right — but it is a decision, and it belongs in the
  write-up rather than in a surprise six weeks later.
- **Is the wording precise?** Titles carry typos, ambiguous nouns and stale
  names. Resolve them against the code; where you can't, they become questions
  in step 3 rather than assumptions in step 4.
- **Is this one piece of work or several?** If it has genuinely independent
  halves, say so and let the user decide — don't silently gather three tickets'
  worth of requirements into one.

**For an initiative, two more:**

- **Is each feature implementable as written?** Take each one literally and ask
  what you would do on Monday. A feature nobody can start from — "make it
  faster", "handle errors properly", "improve the UX" — is not a feature yet,
  and turning it into one is half of this skill's job here.
- **Do the features cover the initiative?** Look for the gaps: the migration
  nobody listed, the permission model, the empty state, the thing that has to
  happen to existing data, the surface an agent reaches over MCP. Also look for
  the opposite — features that belong to a *different* initiative.

Then hunt specifically for **what makes it non-trivial**. Work whose code
change looks like a one-line edit is a signal to keep digging, not a
conclusion: the real work is often entirely outside the diff — a DNS record, a
vendor account or verified identity, a credential someone has to issue, a
deploy that must reach two services and not one. Miss that and the requirements
are a confident lie about the effort.

Keep a hard line between **what you verified in the repo** and **what you
inferred**. They get labelled differently in the output.

## 3. Interview until the picture is complete

The interview is the point of this skill, and it earns its cost only because
step 2 happened first: you are asking someone to choose between real options,
not to explain their own idea back to you. Ask concrete multiple choice —
"should the staging sender use the same domain, or its own?" rather than "any
thoughts on email?". Concrete options cost the user seconds, and they surface
possibilities they hadn't considered. That is what `AskUserQuestion`'s option
lists are for; put your recommendation first and say so.

**Batch into rounds**, up to four questions a round, and let each round's
answers reshape the next. For a ticket, one round is usually right and two is
the ceiling — gathering that costs more of the user's attention than the work
itself has failed at its job. For an initiative, three rounds is usually
plenty; if you are still asking on the fourth, you are either designing the
code (stop) or it is really several initiatives (say so).

The unknowns that most often decide whether the requirements are right:

- **The problem behind it.** The title says *what*; it rarely says what goes
  wrong today, for whom, and how often. The obvious build frequently satisfies
  the title and misses the reason it was filed.
- **What "done" looks like** — the observable that flips it. If you can't name
  one, you don't yet understand it. For an initiative, if *nobody* can name
  one, it is a theme, and it should be split or narrowed.
- **The scope edges.** What is deliberately *out*, and where that work went
  instead. This is the single most valuable answer you will get.
- **The forks step 2 surfaced.** Every place two reasonable choices differ in a
  way someone would notice: copy, defaults, where state lives, what is derived
  versus stored, what happens to users mid-flow, what happens to data already
  written under the old behavior, what is reversible.
- **The architectural bends.** If it needs an invariant to move, put the choice
  to them explicitly, with the cost of each side. Never bend one silently.
- **Ordering and dependencies.** What has to exist first, inside the work and
  outside it — another team, a vendor, a migration that must land alone.
- **Who it is for**, when that is unclear: an internal tool and a customer
  surface are different products with the same title.

**If you would write the same thing either way, don't ask.** Where a
conventional default exists, take it and write the assumption into the
description where it can be contradicted — that's cheaper for everyone than a
question. If it is already specific enough, skip this step and say so.

Then actually **let the answers move you**. Interviewing and then writing the
draft you had already decided on is worse than not asking.

## 4. Draft, at the right altitude

Write for someone with **none** of the context — the filer in six months, or
whoever picks it up. The test for every sentence: *does this help someone
decide what to build, without telling them how to type it?*

The **description** carries:

- **The problem** — what is true today, and what is wrong or missing about it.
- **Why it matters** — who is affected and what it costs them. Work without
  this gets deprioritized forever, correctly.
- **What this is** — the shape of the change in a paragraph, in the system's
  own vocabulary.
- **Where it lands** — the real modules, services, tables and surfaces it
  touches, named. This is the section that proves you opened the repo.
- **Acceptance criteria** — observable statements a third person could check
  without asking you. "Emails send correctly" is not one; "a password-reset
  email arrives with `From: noreply@…` and passes DKIM" is.
- **The decisions taken**, including the ones taken in the interview and the
  options they beat. This is what stops the same argument happening twice.
- **Constraints and invariants** — the ADRs and rules it must live inside, by
  number, and anything it deliberately bends, with the reason.
- **Out of scope** — the adjacent, tempting work this is deliberately not
  doing, and where it went instead.
- **Open questions and assumptions** — everything unresolved, stated plainly.
  Something that admits two unknowns is worth more than something that silently
  guesses.

Never delete a stated constraint just because it is inconvenient.

**For an initiative**, each **feature definition** also gets rewritten so that
it is a thing someone could take. A good one has:

- a **title** that names a capability, not an activity — a reader should be
  able to tell whether it is done;
- a **description** covering what it includes, what it explicitly does not, the
  surface(s) it appears on, and the observable that means it works;
- enough **background** that whoever picks it up does not have to re-derive the
  initiative to understand their piece.

Put them in **build order** where one genuinely depends on another — the order
is read as an argument, so make it one.

Where the investigation says a feature should **not exist** — already built,
belongs to another initiative, or is really three — say so in the draft. Note
that **there is no way to delete a feature definition over MCP**: recommend the
removal, name it clearly, and let the user do it in the web UI. Rewriting an
unwanted feature into a different one to avoid the awkwardness is worse than
saying it plainly.

## 5. Show it, confirm, then write it back

Show the whole draft in chat **before** writing anything: the new description,
and for an initiative each feature as it will read, the new order, the
additions, and the removals you are recommending but cannot make. This is a
proposal about someone else's intent, and they get to correct it while it is
still cheap.

Call out explicitly, at that moment, if you are **overwriting text you didn't
write** — say what is being replaced so the loss is a decision rather than an
accident.

On approval, write in this order, so a failure part-way leaves something
coherent:

1. `mcp__abacus__update_ticket` with the new `description`. Pass **only** that
   field; anything you omit keeps its current value.
2. For an initiative: `mcp__abacus__update_feature` for each rewritten feature.
   **Both fields are replaced** by what you send, so send the title even when
   only the description changed, or you will clear it.
3. `mcp__abacus__add_feature` for each new one.
4. `mcp__abacus__move_feature` to put the list in the order you argued for.
   Positions are 0-based and clamp; move one at a time and re-read if you lose
   track.

**Leave `plan` and `qa_plan` alone — always.** On a feature or a bug they are
`/colormath:plan-ticket`'s output and writing them here would skip the step
that checks this description against the code. On an initiative they are never
written at all: an initiative is not implemented directly, and those fields
belong to the tickets cut from it. On a task the server refuses them outright.

Where the interview produced a decision worth preserving as a record — a
rejected approach, the reasoning behind a scope cut — `add_comment` is its
home. The description should read as the current intent, not its history.

## 6. Move it to the column that names this skill

The requirements are settled, so the ticket has moved on and the board should
say so.

**Ask the board which column that is; never name one.** Call
`mcp__abacus__get_board` with the ticket's `board_id`. It returns the swimlanes
**in board order**, each carrying `exit_commands` — the commands that move work
*on from* that column. Exactly one names this skill; match on the part after the
colon (`gather-requirements`), because the plugin half is configuration and
differs per board.

That lane is the one this work **leaves**, so the ticket goes to the one
**after** it: take the next swimlane in the returned order and
`mcp__abacus__move_ticket` with its `swimlane_id` and `position: 0`. Getting
this off by one moves every ticket backwards, so read the order rather than
assuming it.

This used to be forbidden, and the reason it was is worth knowing: lane meaning
was per board and free text, so one team's "In Review" was another's "Staging"
and guessing at somebody's workflow was worse than leaving the ticket alone.
Abacus columns now come from a board schema and say for themselves which skill
leads into them, so there is nothing left to guess — you are reading the answer,
not inferring it.

Three cases where you do **not** move it, and each is reported rather than
retried:

- **No column names this skill.** A Task Tracker board names none at all, and a
  board on a schema that does not run this process names none either. Leave the
  ticket where it is and say the board does not describe this step.
- **The ticket is in no column at all.** A ticket in the backlog has no status
  to change, and the move is refused: *"Plan this ticket for a release, or file
  it under an initiative, before giving it a status."* That is correct — a lane
  comes from a release or an initiative, and moving a ticket into one is not how
  it gets planned. Report it and let the user decide. **This is the common case
  for a freshly written ticket**, so expect it and do not treat it as a failure
  of the gathering.
- **The move fails for any other reason.** Say so plainly. The description is
  written either way, and a ticket in the wrong column is a smaller problem than
  a report claiming a move that did not happen.

**An initiative moves like anything else** — it is a ticket, it sits in a
column, and its requirements were just settled. Its *children* are not yours to
move; they do not exist yet.

Finish in chat with: the key, what changed, which column it is in now, what you
verified against the code versus assumed, the open questions that survived, and
(for an initiative) the removals the user still has to make by hand. Then say
what happens next:

- a **feature or bug** is ready for `/colormath:plan-ticket`, which writes the
  implementation and QA plans that make it startable;
- an **initiative** waits for **a human to start building** when they are
  ready, which cuts a ticket per feature — you cannot do that and should not
  offer to. After that, `/colormath:plan-initiative` plans the children.
- a **task** is finished. Say so rather than offering a next step it cannot
  take.

Nothing here can delete a ticket — say so plainly if you're asked to.

## Rules

- **Investigate before you interview.** Questions from a cold read are a
  survey; questions after a code pass are a decision. Never open with the
  question round.
- **Stay above the code.** Problem, shape, structure, layers, invariants,
  ordering, acceptance criteria — yes. File-by-file steps, signatures, DDL,
  test lists — no. Those are `/colormath:plan-ticket`'s, and writing them here
  means they were never checked against the code by the skill whose job that
  is.
- **Never write `plan` or `qa_plan`.** Not on a ticket, not on an initiative,
  not "just a start". That boundary is the whole reason this skill and
  `plan-ticket` are two skills.
- **Ask only what changes the outcome**, in batched rounds — two for a ticket,
  three for an initiative, at the absolute most.
- **Never invent an answer the user didn't give.** Unresolved goes in as a
  stated open question or a stated assumption — visibly, where it can be
  contradicted — never silently resolved in your favor.
- **Never bend an architectural rule silently.** If the work needs one to move,
  that is a question for the user and a line in the write-up, by ADR number.
- **Don't implement anything.** No branches, no code edits, no PRs. The
  gathered requirements are the deliverable.
- **Gather this one only.** Don't create, split, reassign or re-type tickets as
  a side effect — if it is really several, recommend the split and let the user
  call it. The **one** move you make is this ticket into the column that names
  this skill, once its description is written; everything else about where
  tickets sit is somebody else's decision.
- **Don't start building.** For an initiative the transition is one-way, it
  locks the features and cuts the tickets, and it is a person's decision —
  there is deliberately no tool for it. If asked, explain and hand back.
- **Confirm before writing**, and never overwrite someone else's description or
  feature text without saying that's what you're doing.
- **Say when it shouldn't be done.** If the investigation shows it is already
  built, already rejected by a recorded decision, or solves a problem that no
  longer exists, that finding *is* the deliverable — report it instead of
  dutifully producing requirements for work nobody needs.
