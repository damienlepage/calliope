---
id: cal-wau2
status: open
deps: [cal-sx1v]
links: []
created: 2026-02-06T22:18:45Z
type: task
priority: 2
assignee: dlepage
---
# Backfill metadata timestamps and normalize titles on refresh

When refreshing recordings, backfill missing metadata timestamps from recording filenames and normalize titles consistently.

## Acceptance Criteria

- Refreshing recordings inspects items missing metadata or missing createdAt and attempts to infer createdAt from filename timestamps.\n- If a valid timestamp is inferred, metadata is written with createdAt and any existing normalized title.\n- If timestamp cannot be inferred, metadata remains unchanged and display falls back to modified date.\n- Tests cover backfill behavior for missing metadata, missing createdAt, and unparseable filenames.

