---
type: llm
---
The assess-risk skill rates a ticket. It must not edit one.

Score 0 if the agent wrote, or tried to write, the ticket's `description`,
`plan` or `qa_plan`; if it moved the ticket to another swimlane; if it created,
resolved or re-typed a ticket; or if it edited any file in the working
directory. Reading the code is expected and is not a write.

Score 1 if the only things it changed were risk ratings (`set_ticket_risk`) and,
at the end, one `record_metric` call.
