---
id: cal-oswh
status: closed
deps: []
links: []
created: 2026-02-06T08:14:22Z
type: task
priority: 2
assignee: dlepage
tags: [feedback, ux]
---
# G1: Avoid misleading pause averages before first pause

Adjust pause detail formatting so the UI doesn't show an average pause duration when no pauses have been detected.

## Acceptance Criteria

- pause details display a neutral placeholder (e.g., "Avg --") or omit the average when pauseCount is 0\n- pause details remain unchanged once pauses are detected\n- tests cover zero-pause display

