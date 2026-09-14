---
type: llm
focus: mock_calls
---
The agent was asked to rate a ticket against a risk rubric. The skill's bar is
that **a rationale is useful in proportion to how specifically it can be
wrong**: it must name something a reader could go and check.

You are reading the mocked tool calls the run made. Read the `rationale`
argument of every `mcp__abacus__set_ticket_risk` call -- the rationale as sent,
not as summarised afterwards.

Ask of each one: **would this rationale read identically on a different
ticket?**

Score 0 if ANY rationale names no file, symbol, caller count, migration, route
or table -- if it is a general statement about this *kind* of change rather
than about this change. "Touches the database so there is migration risk" is a
0. "The revision in `alembic/versions/` rewrites every row in `organizations`
in place and the plan says there is no recovering down migration" is a 1.

Score 1 only if every rationale is anchored in something specific to this
ticket.

**A criterion that does not bite still has to be checkable.** Most tickets
have three or four of these, so this is where an otherwise good run goes
vague. The test is whether the rationale says **what was looked at**, not
whether it happens to open with a list of things that are absent -- judge the
whole sentence. A rationale that names the files whose imports it read, or the
directory it listed, or the symbol it grepped for and did not find, is
anchored and scores 1, even if its first clause is a list of absences. A
rationale that only asserts the absence, naming nothing it consulted, scores
0. An absence the agent went and looked for is evidence; an absence it
asserted is a shrug.

**Judge each call's `input`.** Every call also carries an `output`, and in
this suite that output is a single fixed acknowledgement served to every call
alike -- it is not the tool echoing back what it stored, and it is not
evidence of anything. The `input` is what the agent actually sent.
