---
id: cal-u849
status: closed
deps: []
links: []
created: 2026-02-06T07:17:03Z
type: task
priority: 2
assignee: dlepage
tags: [recordings, privacy, ux]
---
# Recordings: Block delete while recording

Prevent deleting recordings while a live capture is in progress to avoid corrupting active files.

## Acceptance Criteria

- When recording is active, delete requests do not set a pending delete.
- Confirming delete while recording does not delete any files and shows a gentle error message.
- Recordings view disables delete actions while recording.
- Unit tests cover delete behavior when recording is active.

