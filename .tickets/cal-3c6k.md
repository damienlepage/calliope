---
id: cal-3c6k
status: ready
deps: []
links: []
created: 2026-02-05T00:41:00Z
type: task
priority: 2
assignee: dlepage
---
# MVP: First-launch privacy disclosure sheet

Ensure new users explicitly acknowledge privacy guardrails with a dedicated first-launch sheet that cannot be dismissed without acceptance.

## Acceptance Criteria

- On first launch (when the disclosure has not been accepted), present a modal sheet with the disclosure title/body and settings statements.
- The sheet includes a single "I Understand" action that sets the persisted acceptance flag.
- The sheet is not dismissible until acceptance is recorded.
- After acceptance, the sheet does not appear on subsequent launches.
- Unit tests cover persistence and the first-launch gating logic.
