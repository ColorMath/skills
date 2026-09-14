---
name: assess-risk
description: Rate a ticket against the engineering-risk rubric Abacus declares — read the ticket, read the criteria out of the tool, go and look at the code each one asks about, then write back one level and one specific rationale per criterion. Use this whenever someone wants a ticket assessed, rated, risk-scored, "weighed before we pick it up", or asks how dangerous a piece of work is — or names a ticket key (CM-00001) and asks what could go wrong with it. Not for deciding what to build (that's /colormath:gather-requirements), not for deciding how to build it (that's /colormath:plan-ticket), and not for finding defects in something already built (that's /colormath:qa). The rating is advisory: nothing here refuses anything.
argument-hint: [ticket key, e.g. CM-00001 — or enough of the title to find it]
allowed-tools: Bash Read Grep Glob mcp__abacus__get_ticket mcp__abacus__set_ticket_risk mcp__abacus__record_metric mcp__abacus__list_projects mcp__abacus__list_tickets mcp__abacus__add_comment
---

Rate the ticket named in "$ARGUMENTS" against the engineering-risk rubric, so
that somebody deciding whether to pick it up knows what they are taking on.

A ticket already says what it is, where it is, what it is for, and what
somebody intends to do about it. It says nothing about **how badly it can go
wrong**. Two features with identical plans and identical QA plans are not
identically safe to start, and the moment that bites is the one where a ticket
is sitting in a column waiting for somebody to choose it.

The failure mode this skill exists to prevent is **the rationale that could
have been written without opening the repo**: "this touches the database, so
there is some migration risk". It names no file, no caller, no table; it would
read identically on forty other tickets; and nobody can contradict it, which is
the same as nobody being able to trust it. **A rationale is useful in
proportion to how specifically it can be wrong.**

So the spine is **read → read the rubric → investigate → write one rating per
criterion → report → record.** Five questions, five visits to the code, five
sentences somebody could argue with.

Quote the ticket by its **key** (`CM-00001`) throughout — that's what people
call it by, never the UUID.

## 1. Read the ticket, and check this is the right skill for it

Call `mcp__abacus__get_ticket`. It takes the key directly, and case and
zero-padding don't matter, so `cm-1` resolves. If "$ARGUMENTS" is a title
fragment rather than a key, find it with `list_projects` then `list_tickets` and
confirm which one you landed on.

**Read `type` first, because two of the four stop here:**

- **`feature` or `bug`** — carry on. These are the types the rubric is about.
- **`initiative`** — the wrong altitude. An initiative is not implemented
  directly; the risk lives in the tickets cut from it, and rating the container
  rates nothing. Say so, list the children `get_ticket` returned, and **offer to
  assess them** — one at a time, by key. Do not rate the initiative itself.
- **`task`** — a task is work that isn't code. Blast radius, migrations and
  authorization surface are questions about a diff, and there is no diff. Say
  so and stop.

Then read all of it: description, implementation plan, QA plan, **every
comment**, the release, and the initiative it sits under. The plan is the
single most useful thing on the page, because it is the closest thing to the
diff that does not exist yet — a plan that names `alembic/versions/` is telling
you about `data_and_migration` before you have opened anything.

**Read the ratings it already has.** `get_ticket` returns them under `risk`. If
there are any, you are **revising, not authoring**: read each existing rationale
as evidence of what somebody already went and looked at, keep what is still
true, and when you change a level say in your report what changed and why.
Re-rating a criterion overwrites it, and the old text survives only in the
audit trail — so a rewrite that loses somebody's reasoning is a real loss, not
a tidy-up.

**Revising still means every criterion.** Agreeing with a rating is not the
same as leaving it alone: a criterion you did not send is one nobody has
looked at since whoever rated it last, and your report will say you assessed
the ticket. So send all of them, and where you agree, say so in the rationale
and say what you checked that made you agree. "Keep what is still true" is
about the reasoning, not about the call.

**If `mcp__abacus__set_ticket_risk` is not available to you, stop.** Say the
Abacus this project is connected to does not offer risk ratings — it is an
older deployment — and that the assessment cannot be recorded. **Do not fall
back to writing it as a comment.** A comment is not a rating: nothing reads it
as one, the ticket still shows as unassessed, and the next person to run this
skill will have no idea the work was already done. An honest "I cannot record
this here" is worth more than an assessment filed in the wrong place.

## 2. Read the rubric from the tool, not from memory

**Do not carry a list of criteria in your head, and do not take one from this
file.** The rubric is declared in Abacus's code and generated into
`set_ticket_risk`'s own schema: the `criterion` argument's `enum` is the
authoritative list of keys, and its description carries what each one asks
about. The `level` argument does the same for the levels.

Read them off the tool at the start of every run. That is the whole bargain the
tracker made when it put the rubric in code — a criterion added or retired
there reaches this skill on its next call, with no edit here. A skill that
spells the criteria out is a second copy of the rubric, and the second copy is
the one that goes stale.

Two consequences worth stating plainly, because both are easy to get wrong:

- **Rate every criterion the tool offers, not five.** If the enum has six, write
  six. If it has four, write four and do not invent the fifth from memory.
- **Use the level keys the tool offers.** Do not translate them into words of
  your own — "moderate", "critical", "n/a" — and do not skip a criterion by
  rating it with something that isn't in the enum. A criterion that does not
  bite on this ticket is the **lowest** level, with a rationale saying why it
  does not bite. That is a real finding and it is worth writing.

## 3. Go and look, once per criterion

This is where the time goes, and it is what separates a rating from a guess.
Each criterion is a question about the code, and you answer it by opening the
code — the routes, services, models, migrations, templates, jobs and config the
ticket's plan names, plus everything that calls them.

Work criterion by criterion, and for each one come back with something
countable. What that looks like in practice, for the rubric Abacus ships today
— read the tool's own descriptions as the authority, and treat these as how to
go and find the answer rather than as the questions themselves:

**Blast radius** — how much breaks if this is wrong. Do not estimate it; count
it. Grep for every caller of the function or template the change lands in, and
say how many there are and what they are. One admin screen and "every
authenticated request" are both blast radii, and the difference between them is
the whole of the rating.

**Reversibility** — how hard it is to undo once it is live. This is the
criterion whose direction is most often inverted, so say the direction out
loud as you rate it: **easy to undo is low risk; impossible to undo is high**.
A pure code change reverts with the commit. A change that writes data other
things then read, or that hands something to a third party, or that people see
and act on, does not come back with a revert.

**Data and migration** — whether it rewrites or destroys stored data, and
whether the rewrite can be replayed. Open the migration if the plan names one.
A `DROP COLUMN` and an additive nullable column are not the same rating, and
the file says which it is. An `UPDATE` with no recorded before-state is worse
than either.

**Security and authorization** — whether it touches authentication,
authorization, tenancy scoping, secrets, or anything a stranger can reach.
Name the boundary it touches: the route's permission check, the organization
filter on the query, the token it decrypts. "This is internal" is not a finding
unless you looked at who can reach the route.

**External dependency** — how much it rests on something outside this repo: an
API, a release in another repository, somebody else's schedule. A ticket whose
"done" requires a tag in a second repo is carrying that dependency whether or
not anyone wrote it down.

Then write each rationale so that it could not be moved to a different ticket
without becoming false. Name the file, the symbol, the number of callers, the
migration, the route. **A rationale is useful in proportion to how specifically
it can be wrong** — a sentence nobody can check is a sentence nobody has any
reason to believe, and the rubric exists precisely because a bare level is that
sentence with the words taken out.

**A criterion that does not bite here is still a finding, and it is the one
most likely to come out empty.** "No external APIs are involved" and "no
migration is planned" are assertions: nothing in them can be checked, and
they would read identically on half the tickets in the project. Say what you
looked at instead — the directory you listed, the thing you grepped for and
did not find, the file the plan names that turned out not to exist. "Nothing
under `alembic/versions/` is touched; the only revision there is the initial
schema" is a `low` somebody can go and disprove. An absence you searched for
is evidence; an absence you assumed is a shrug.

Keep the hard line between **what you verified** and **what you inferred**, and
put the inference in the rationale as an inference. "The plan says a migration;
I did not find one on disk yet" is a better rationale than either half alone.

## 4. Write one rating per criterion

One `mcp__abacus__set_ticket_risk` call per criterion, with all four arguments:
the ticket's `id`, the `criterion` key, the `level` key, and the `rationale`.
There is no batch call and that is deliberate — each write is atomic, each
lands its own audit events, and a run that dies halfway has recorded what it
had actually decided rather than nothing.

The rationale is **markdown source**, stored as written and rendered when read.
Keep it to a few sentences. This is a judgement somebody reads on the way past,
not a report.

**High always means more risk.** Every criterion is phrased so that the worst
answer is the top level, and the temptation to invert one is real:
*reversibility* reads like a virtue, so "this is highly reversible" wants to be
rated high, and that is exactly backwards — an easily reversed change is **low**
risk. Read the level descriptions the tool gave you before each write and make
sure the direction is the rubric's, not the English word's.

Nothing here is refused and nothing is gated on the result. A ticket rated high
on all five is still startable; the rating tells the person starting it what to
have ready.

## 5. Say what you rated, and where you are least sure

Report in chat, per criterion: the level, the sentence behind it, and the
evidence you actually opened. Then two things the ratings themselves cannot
carry:

- **Which rating you are least confident in**, and what would settle it. An
  assessment that presents five equally confident sentences is hiding the one
  that matters.
- **Anything you found that is not a risk rating** — a step in the plan that no
  longer matches the code, a missing migration, a caller nobody listed. Say it;
  do not file it. Changing the ticket is somebody else's job.

If you are revising, say which levels moved and why.

## 6. Record that you ran

Abacus cannot see this happen. Nothing outside your own run knows a skill
started, so a run you do not record did not happen as far as the ticket is
concerned — and the counts worth having are the ones nobody wants: a ticket
assessed three times is one whose risk nobody could agree on.

`mcp__abacus__record_metric` with the ticket's `id`, `metric: "skill_invoked"`,
and `subject: "assess-risk"` — the bare name, never the whole command, because
the plugin half is configuration and differs per project.

**Once, at the end, and only if you did the work.** Not on every turn and not
when you begin. If you stopped at step 1 because the ticket was a task or an
initiative, record nothing: a run that did not happen must not leave a row
saying it did.

**The rows are append-only.** Nobody can edit or delete one, you included, so a
wrong subject or a double-record is permanent.

If the call fails, say so in your report and carry on. The ratings are written
either way, and a report claiming a measurement it did not take is worse than a
missing row.

## Rules

- **Never move the ticket.** This skill is not a step in the process — it is a
  thing somebody does to a ticket wherever it is sitting, and no column names
  it. A ticket that changes lane because it was assessed has been moved by the
  assessment, which is the opposite of advisory.
- **Never write `description`, `plan` or `qa_plan`.** Those belong to
  `/colormath:gather-requirements` and `/colormath:plan-ticket`, and this skill
  holds no `update_ticket` tool for exactly that reason. If the plan is wrong,
  say so in your report.
- **Don't implement anything.** No branches, no code edits, no PRs. You are
  reading the code to rate it, not to change it.
- **Rate what the tool offers, and only that.** No criterion from memory, no
  level of your own invention, no sixth question because it seemed important.
  If the rubric is missing something, that is a finding about the rubric —
  report it and let somebody edit `core/risk.py`.
- **Every rationale names something checkable.** A file, a symbol, a count, a
  migration, a route. A rationale that would read identically on another ticket
  has not been written yet.
- **Mandatory means mandatory.** A level with no rationale is the bare word the
  rubric exists to prevent, and the tool refuses it anyway.
- **Nothing is refused over a rating**, including by you. Do not recommend
  blocking, holding or descoping the work on the strength of your own
  assessment — say what is risky and let the person deciding decide.
- **Say when a ticket should not be assessed at all.** Already shipped, already
  abandoned, or so thin that every rationale would be a guess — that finding is
  the deliverable, and it is worth more than five sentences of hedging.
