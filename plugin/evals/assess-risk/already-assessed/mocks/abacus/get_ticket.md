---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000704",
  "key": "CM-00704",
  "title": "Encrypt the organization settings blob at rest",
  "type": "feature",
  "description": "`organizations.settings` is a plain string column holding JSON, and some of what tenants put in it is credential-shaped. Encrypt it at rest with a key from the environment, decrypting on read.\n\nDone when: the column holds ciphertext, reads are transparent, and a row written before this change still reads.",
  "plan": "1. `core/database.py` \u2014 a `Encrypted` TypeDecorator wrapping `String`.\n2. `models/organization.py` \u2014 `settings` takes that type.\n3. `alembic/versions/` \u2014 a revision re-writing every existing row through the new type. There is no down migration that recovers a row written after the key rotates.\n4. `docker-compose.yml` \u2014 `SETTINGS_KEY` in the environment block.",
  "qa_plan": "- A pre-existing row reads back unchanged.\n- The raw column is unreadable in psql.\n- A missing `SETTINGS_KEY` fails at boot rather than at first read.",
  "swimlane_id": "sw-ready",
  "swimlane_name": "Ready for Implementation",
  "assignee_id": null,
  "project_id": "pppppppp-0000-0000-0000-000000000001",
  "initiative_id": null,
  "initiative_status": null,
  "comments": [],
  "metrics": [],
  "risk": [
    {
      "criterion": "blast_radius",
      "level": "medium",
      "rationale": "`settings` is read on the organization row itself, which `models/ticket.py` joins through a foreign key. One column, one model.",
      "updated_by": "Ada Kowalski"
    },
    {
      "criterion": "data_and_migration",
      "level": "high",
      "rationale": "The revision rewrites every row in `organizations` in place and the plan states there is no down migration that recovers a row written after a key rotation.",
      "updated_by": "Ada Kowalski"
    },
    {
      "criterion": "external_dependency",
      "level": "low",
      "rationale": "The key comes from `docker-compose.yml`'s environment block. Nothing outside this repo has to ship first.",
      "updated_by": "Ada Kowalski"
    }
  ]
}
