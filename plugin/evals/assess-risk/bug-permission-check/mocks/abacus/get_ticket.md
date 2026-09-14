---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000702",
  "key": "CM-00702",
  "title": "check_permission denies members their own tickets",
  "type": "bug",
  "description": "`core/permissions.py::check_permission` returns True only for `admin`, so a `member` is refused every action including reading a ticket they filed. `ROLES` lists three roles and the function implements one.\n\nReported by two people this week; the workaround being used is making people admins, which is the reason this is urgent rather than tidy.\n\nDone when: a member may read and comment on tickets in their own organization, and a viewer still may not write.",
  "plan": "1. `core/permissions.py` \u2014 replace the admin-only branch with a role/action table covering all three entries in `ROLES`.\n2. `routes/tickets.py` \u2014 both handlers already call through; no change expected, but confirm nothing else short-circuits on role.\n3. `tests/test_tickets.py` \u2014 a case per role per action.",
  "qa_plan": "- A member reads a ticket in their organization: 200.\n- A member reads a ticket in another organization: 404.\n- A viewer attempts a write: 403.\n- An admin is unaffected.",
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
