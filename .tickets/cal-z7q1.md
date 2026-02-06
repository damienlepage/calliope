---
id: cal-z7q1
status: closed
deps: []
links: []
created: 2026-02-06T10:00:00Z
type: task
priority: 2
assignee: dlepage
tags: [recordings, settings, storage]
---
# Recordings: add Settings action to open local recordings folder

Improve storage cues by letting users open the local recordings folder directly from Settings.

## Acceptance Criteria

- Settings shows an "Open Recordings Folder" action adjacent to the storage path text.
- The action opens the recordings directory via `NSWorkspace` (through a testable abstraction).
- Unit tests cover the action model using a mock workspace and recording manager.

## Outcome

- Added a Settings action to open the local recordings folder via a new action model.
- Settings now shows an "Open Recordings Folder" button near the storage path.
- Added unit coverage for the action model.
