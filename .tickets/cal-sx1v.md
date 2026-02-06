---
id: cal-sx1v
status: closed
deps: []
links: []
created: 2026-02-06T22:18:41Z
type: task
priority: 2
assignee: dlepage
---
# Add recording metadata timestamps for consistent naming

Extend RecordingMetadata to include a createdAt timestamp used for consistent display when filenames or modified dates change.

## Acceptance Criteria

- RecordingMetadata includes a createdAt field (ISO8601 Date) that is optional for legacy files.\n- When metadata is present with createdAt, recordings list/detail use createdAt for default Session date display.\n- Writing metadata (session title save) persists createdAt for all recording URLs in the session.\n- Unit tests cover metadata encode/decode and display name selection with createdAt.

