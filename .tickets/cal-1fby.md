---
id: cal-1fby
status: open
deps: []
links: []
created: 2026-02-06T16:37:11Z
type: task
priority: 3
assignee: dlepage
tags: [long-session, storage]
---
# G8: Split long recordings into manageable segments

Keep multi-hour recordings stable by optionally segmenting very long sessions into rolling files without losing analysis continuity.

## Acceptance Criteria

- Introduce a configurable max segment duration (default: 2 hours) for recordings.\n- When recording exceeds the limit, close the current file and start a new segment seamlessly.\n- Analysis summaries should still reflect the full session, and recordings list should surface segments as a grouped entry or clearly labeled parts.\n- Add tests for segment rollover behavior.\n- No new dependencies.

