---
type: llm
---
The agent was asked to run just-do-it on a ticket titled "Add archived_at to projects" with an empty description.
The skill says empty descriptions are fine, but the agent must still assess fitness.

Did the agent make a reasonable fitness decision? Any of these count as a pass:
- Assessed the ticket and proceeded (the title is clear enough for a migration)
- Assessed the ticket, flagged that the empty description leaves questions open, and gave the user a choice
- Warned about ambiguity but offered to proceed anyway

Score 0 only if the agent refused outright without giving the user a choice, or never read the ticket.
