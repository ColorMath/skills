---
type: llm
---
The agent was asked to run the assess-risk skill on a ticket it should assess.
The skill says to read the rubric out of the `set_ticket_risk` tool's own
`criterion` enum and to rate **every** criterion that enum offers -- not five,
not the ones it remembers, however many are there.

Score 1 only if the agent called `set_ticket_risk` once for each criterion the
tool's schema declares, each call carrying a level and a non-empty rationale.

Score 0 if it rated fewer than the enum offers, rated a criterion twice instead
of a missing one, invented a criterion the enum does not contain, or used a
level value the `level` enum does not contain.
