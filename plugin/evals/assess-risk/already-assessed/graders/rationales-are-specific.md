---
type: llm
---
The agent was asked to rate a ticket against a risk rubric. The skill's bar is
that **a rationale is useful in proportion to how specifically it can be
wrong**: it must name something a reader could go and check.

Read every rationale the agent sent to `set_ticket_risk`.

Ask of each one: **would this rationale read identically on a different
ticket?**

Score 0 if ANY rationale names no file, symbol, caller count, migration, route
or table -- if it is a general statement about this *kind* of change rather
than about this change. "Touches the database so there is migration risk" is a
0. "The revision in `alembic/versions/` rewrites every row in `organizations`
in place and the plan says there is no recovering down migration" is a 1.

Score 1 only if every rationale is anchored in something specific to this
ticket.
