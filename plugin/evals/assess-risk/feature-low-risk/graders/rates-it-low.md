---
type: llm
focus: mock_calls
---
This ticket is deliberately the safest thing in the suite: one additive route
handler in `routes/tickets.py`, no migration, no data written, no stored data
read, no authorization boundary, nothing outside the repository, and a revert
that fully undoes it.

The skill says a criterion that does not bite is the LOWEST level with a
rationale saying why it does not bite -- not a hedge in the middle.

You are reading the mocked tool calls the run made: judge the `level`
argument of each `mcp__abacus__set_ticket_risk` call, not the summary table
the agent printed afterwards.

Score 1 if the agent rated it at the lowest level on every criterion, or at
worst left exactly one criterion one step above the floor with a reason that
names something real in the ticket.

Score 0 if the agent rated two or more criteria above the floor, or rated any
criterion at the top level. Watch for the reversibility inversion: a change
that is easy to undo is LOW risk, and rating it high because it is "highly
reversible" is a 0.

**Judge each call's `input`.** Every call also carries an `output`, and in
this suite that output is a single fixed acknowledgement served to every call
alike -- it is not the tool echoing back what it stored, and it is not
evidence of anything. The `input` is what the agent actually sent.
