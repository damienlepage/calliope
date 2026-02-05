---
id: cal-blbq
status: closed
deps: []
links: []
created: 2026-02-05T04:52:38Z
type: task
priority: 2
assignee: dlepage
---
# Normalize analysis preferences

Normalize persisted analysis preferences to keep live analysis stable.

## Acceptance Criteria

- If stored paceMin > paceMax, values are swapped so paceMin <= paceMax.\n- If stored pauseThreshold <= 0, it falls back to Constants.pauseThreshold.\n- Stored crutch words are trimmed, lowercased, and deduplicated while preserving order.\n- Unit tests cover normalization behavior.

