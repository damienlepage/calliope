---
id: cal-4v6t
status: closed
deps: []
links: []
created: 2026-02-05T20:10:00Z
type: task
priority: 2
assignee: dlepage
---
# Add Sound settings shortcut when no microphone is available

Provide a direct action for users to open macOS Sound input settings when no microphone input device is detected.

## Acceptance Criteria
- When Start is disabled because no microphone input device is available, the status UI shows an "Open Sound Settings" action.
- The action opens the system Sound input settings pane locally.
- The action is hidden when a microphone device is available or permission is blocking Start for other reasons.
- Unit tests cover action visibility and invocation with a mocked settings opener.
- No network usage is introduced.
