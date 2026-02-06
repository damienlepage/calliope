---
id: cal-3r4u
status: closed
deps: []
links: []
created: 2026-02-06T23:50:09Z
type: task
priority: 2
assignee: dlepage
tags: [metadata, recordings]
---
# Normalize session metadata inputs

Harden session title entry and metadata normalization for recordings.

## Acceptance Criteria

- Title input is trimmed and normalized (no leading/trailing whitespace).
- Empty/whitespace-only titles fall back to default session name.
- A maximum title length is enforced with safe truncation.
- Normalized title is persisted consistently across recording metadata.
- Unit tests cover normalization and fallback behavior.

