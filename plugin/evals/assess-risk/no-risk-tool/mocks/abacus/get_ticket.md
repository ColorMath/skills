---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000803",
  "key": "CM-00803",
  "title": "Index tickets by organization",
  "type": "feature",
  "description": "`models/ticket.py` has a foreign key to `organizations.id` and no index on it, so every per-organization listing is a sequential scan.\n\nDone when: the index exists and the listing query uses it.",
  "plan": "1. `models/ticket.py` \u2014 `index=True` on `organization_id`.\n2. `alembic/versions/` \u2014 a revision creating it concurrently.",
  "qa_plan": "- The index exists after `make migrate`.\n- `EXPLAIN` on the listing query names it.\n- `down()` drops it.",
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
