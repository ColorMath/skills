---
---
{
  "id": "pppppppp-0000-0000-0000-000000000001",
  "name": "ColorMath Platform",
  "swimlanes": [
    {
      "id": "sw-req",
      "name": "Ready for Requirements",
      "exit_commands": [
        {
          "skill": "gather-requirements",
          "command": "/colormath:gather-requirements",
          "leads_to": "sw-plan"
        }
      ]
    },
    {
      "id": "sw-plan",
      "name": "Ready for Planning",
      "exit_commands": [
        {
          "skill": "plan-ticket",
          "command": "/colormath:plan-ticket",
          "leads_to": "sw-impl"
        }
      ]
    },
    {
      "id": "sw-impl",
      "name": "Ready for Implementation",
      "exit_commands": [
        {
          "skill": "implement-ticket",
          "command": "/colormath:implement-ticket",
          "leads_to": "sw-ship"
        }
      ]
    },
    {
      "id": "sw-ship",
      "name": "Implementing",
      "exit_commands": [
        {
          "skill": "ship",
          "command": "/colormath:ship",
          "leads_to": "sw-done"
        }
      ]
    },
    {
      "id": "sw-done",
      "name": "Done",
      "exit_commands": []
    }
  ],
  "repositories": [
    {
      "id": "repo-1",
      "full_name": "ColorMath/platform"
    }
  ]
}
