---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000701",
  "key": "CM-00701",
  "title": "Soft-delete organizations",
  "type": "feature",
  "description": "Deleting an organization today removes the row, and every ticket and comment under it goes with the cascade. Support soft deletion instead: a nullable `deleted_at` on `organizations`, filtered out of the default read path so a deleted organization stops appearing without its data being destroyed.\n\nDone when: a deleted organization returns 404 from `/api/v1/projects/` and its tickets still exist in the database.",
  "plan": "1. `models/organization.py` \u2014 add `deleted_at = Column(DateTime, nullable=True)` to `Organization`.\n2. `alembic/versions/` \u2014 a new revision off `0001` adding the column, then a data step marking every organization whose `settings` carries `\"archived\": true` as deleted and clearing that key.\n3. `routes/projects.py` \u2014 filter `deleted_at IS NULL` in `list_projects()`.\n4. `core/permissions.py` \u2014 `check_permission` returns False for any action on a deleted organization.",
  "qa_plan": "- Soft-delete an organization; `GET /api/v1/projects/` omits it.\n- Its tickets are still selectable directly.\n- The migration's data step is re-runnable.\n- `down()` drops the column and leaves the rows.",
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
