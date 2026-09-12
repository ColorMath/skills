---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000502",
  "key": "CM-00502",
  "title": "Pagination returns duplicate rows on page boundary",
  "type": "bug",
  "description": "When the last row on page N has the same created_at as the first row on page N+1, both pages include it. Use (created_at, id) as the cursor key instead of created_at alone.",
  "plan": null,
  "qa_plan": null,
  "swimlane_id": "sw-req",
  "swimlane_name": "Ready for Requirements",
  "assignee_id": null,
  "project_id": "pppppppp-0000-0000-0000-000000000001",
  "initiative_id": null,
  "initiative_status": null,
  "comments": [],
  "metrics": []
}
