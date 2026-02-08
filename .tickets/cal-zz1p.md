---
id: cal-zz1p
status: closed
deps: []
links: []
created: 2026-02-08T00:35:00Z
type: task
priority: 1
assignee: dlepage
---
# Align post-stop session naming with PRD sheet

Restore the macOS-style sheet prompt for optional session titles after Stop without blocking access to stats, keeping the session feedback panel visible and greyed out.

## Acceptance Criteria

- Stopping a session presents a sheet that allows entering an optional session title with Save and Skip actions.
- Dismissing the sheet leaves the session screen accessible; stats remain available via Recordings.
- The session screen stays in place with greyed feedback and the primary action becoming Resume.
- Unit test coverage exists for the new sheet view.
