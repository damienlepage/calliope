---
id: cal-nizh
status: closed
deps: []
links: []
created: 2026-02-06T22:39:25Z
type: task
priority: 3
assignee: dlepage
---
# G24: Write default metadata on session completion

Ensure completed sessions always get a metadata file (default title + createdAt) immediately after stop, even if the user skips the title prompt.

## Acceptance Criteria

- When recording stops and a completed session is published, write metadata with default title + createdAt for all segment URLs before title prompt actions.\n- If user saves a custom title, metadata is updated with normalized title.\n- Tests cover default metadata write on completion.

