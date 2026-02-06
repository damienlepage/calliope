---
id: cal-61vu
status: closed
deps: []
links: []
created: 2026-02-06T16:37:08Z
type: task
priority: 2
assignee: dlepage
tags: [long-session, analysis]
---
# G8: Persist periodic analysis checkpoints during long recordings

Reduce data loss risk in multi-hour sessions by writing interim analysis summaries on a schedule.

## Acceptance Criteria

- While recording, write an interim analysis summary at a fixed interval (ex: every 5 minutes).\n- Interim summary writes should not disrupt the final summary on stop; final summary still reflects full session.\n- No writes occur when not recording.\n- Add unit tests for the checkpoint schedule and write calls (with a controllable clock/timer).\n- No new dependencies.

