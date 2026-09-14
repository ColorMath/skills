---
---
{
  "id": "aaaaaaaa-bbbb-cccc-dddd-000000000705",
  "key": "CM-00705",
  "title": "Publish ticket changes to the activity queue",
  "type": "feature",
  "description": "Nothing outside the database learns that a ticket changed. Publish one message per write to a queue the notifications service consumes.\n\nDone when: creating and updating a ticket each emit exactly one message, and a failure to publish does not fail the write.",
  "plan": "1. `adapters/` \u2014 a publisher wrapping the queue client.\n2. `routes/tickets.py` \u2014 call it after each write.\n3. `docker-compose.yml` \u2014 the broker, and `QUEUE_URL`.\n4. The notifications service in another repository has to be consuming the topic before this is switched on.",
  "qa_plan": "- One message per write, with the ticket key in the body.\n- A broker that is down logs and does not 500 the write.\n- Replaying a message twice is harmless downstream.",
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
