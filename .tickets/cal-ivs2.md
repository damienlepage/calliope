---
id: cal-ivs2
status: closed
deps: []
links: []
created: 2026-02-06T05:34:31Z
type: task
priority: 2
assignee: dlepage
---
# Neutral Pace Feedback Before Speech

## Description
Pace feedback currently treats a zero pace as "Slow", which can feel like a warning before any speech is detected. Adjust pace feedback to surface a neutral "Listening" state when pace data is not yet available, and reflect that in the live feedback UI.

## Acceptance Criteria
- Pace feedback returns a neutral state and "Listening" label when pace is zero or below.
- Live feedback UI shows a neutral pace color and placeholder value when pace is zero.
- Tests cover the new pace feedback behavior.
