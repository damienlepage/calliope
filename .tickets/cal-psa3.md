---
id: cal-psa3
status: ready
deps: []
links: []
created: 2026-02-07T20:17:00Z
type: task
priority: 3
assignee: dlepage
tags: [session, feedback, ui]
---
# G34: Feedback visualization polish for calm focus

Refine the live feedback visuals (pace, crutch words, pauses, input level, elapsed time) to be calmer and more intuitive.

## Acceptance Criteria

- Live feedback panel uses a clearer visual hierarchy: primary metric (pace) and secondary metrics (crutch words, pauses, input level, elapsed time).
- Replace any harsh alert styling with calmer warning treatments that still surface issues (e.g., muted color, icon + text).
- Ensure all feedback tiles align to a consistent grid and spacing system.
- Verify colors meet accessibility contrast for text and essential statuses.
- Add/adjust snapshots or unit UI tests if available for the session view.
- No new dependencies.

## Notes

Keep changes incremental; avoid major layout refactors.
