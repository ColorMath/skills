---
type: llm
focus: mock_calls
---
The agent was asked to run the assess-risk skill on a ticket it should assess.
The skill says to read the rubric out of the `set_ticket_risk` tool's own
`criterion` enum and to rate **every** criterion that enum offers -- not five
because it remembers five, however many are actually there.

The mock in this case declares exactly 5, and these are they:
`blast_radius`, `reversibility`, `data_and_migration`, `security_and_authorization`, `external_dependency`. The legal levels are `low`, `medium` and `high`.

You are reading the mocked tool calls the run made, each with its arguments.

**This ticket already carries three ratings**, and `get_ticket` returns them
in its `risk` array: `blast_radius`, `data_and_migration` and
`external_dependency`, rated by somebody else. Those are **not calls the run
made** -- they are what it read before deciding. A run that agrees with one of
them and sends it again has rated that criterion **once**, not twice, and the
skill requires it to send all five whether or not it changed them. Count only
`mcp__abacus__set_ticket_risk` calls when you ask whether something was rated
twice; a criterion appearing once in `get_ticket`'s output and once as a call
is the normal, correct shape for this case.

Score 1 only if there is exactly one `mcp__abacus__set_ticket_risk` call per
criterion in that list, each carrying a `level` from that list of levels and a
`rationale` that is not empty.

Score 0 if a criterion in the list was never rated, if one was rated twice, if
a call names a criterion key that is not in the list, if a call uses a level
that is not in the list, or if any rationale is empty.

**Judge each call's `input`.** Every call also carries an `output`, and in
this suite that output is a single fixed acknowledgement served to every call
alike -- it is not the tool echoing back what it stored, and it is not
evidence of anything. The `input` is what the agent actually sent.
