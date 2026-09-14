---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000703",
  "key": "CM-00703",
  "title": "Add a health endpoint to the tickets router",
  "type": "feature",
  "description": "Deploys are currently checked by hand. Add `GET /api/v1/tickets/health` returning `{\"status\": \"ok\"}` so the platform's uptime check has something cheap to poll.\n\nIt reads nothing and writes nothing \u2014 it exists to prove the router is mounted.\n\nDone when: the route returns 200 with that body, and nothing else changes.",
  "plan": "1. `routes/tickets.py` \u2014 add a `@router.get(\"/health\")` handler returning a literal dict. Declare it above `get_ticket`, whose `/{key}` would otherwise match it.\n2. `tests/test_tickets.py` \u2014 one case asserting 200 and the body.",
  "qa_plan": "- `curl /api/v1/tickets/health` returns 200 and `{\"status\": \"ok\"}`.\n- `GET /api/v1/tickets/health` does not resolve as a ticket key.\n- No other route's response changes.",
  "swimlane_id": "sw-ready",
  "swimlane_name": "Ready for Implementation",
  "assignee_id": null,
  "project_id": "pppppppp-0000-0000-0000-000000000001",
  "initiative_id": null,
  "initiative_status": null,
  "comments": [],
  "metrics": [],
  "risk": []
}
