---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000801",
  "key": "CM-00801",
  "title": "Tenant isolation, end to end",
  "type": "initiative",
  "description": "Every query in the repo should be scoped to the caller's organization, and today most are scoped by whichever route remembered to. This is the programme that makes it structural.",
  "plan": null,
  "qa_plan": null,
  "swimlane_id": "sw-ready",
  "swimlane_name": "Ready for Implementation",
  "assignee_id": null,
  "project_id": "pppppppp-0000-0000-0000-000000000001",
  "initiative_id": null,
  "initiative_status": "building",
  "comments": [],
  "metrics": [],
  "risk": [],
  "features": [
    {
      "position": 0,
      "title": "Scope the ticket queries",
      "description": "..."
    },
    {
      "position": 1,
      "title": "Scope the comment queries",
      "description": "..."
    },
    {
      "position": 2,
      "title": "A test that fails on an unscoped query",
      "description": "..."
    }
  ],
  "children": [
    {
      "key": "CM-00811",
      "title": "Scope the ticket queries",
      "type": "feature"
    },
    {
      "key": "CM-00812",
      "title": "Scope the comment queries",
      "type": "feature"
    },
    {
      "key": "CM-00813",
      "title": "A test that fails on an unscoped query",
      "type": "feature"
    }
  ]
}
