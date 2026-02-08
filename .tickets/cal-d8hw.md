---
id: cal-d8hw
status: closed
deps: []
links: []
created: 2026-02-07T23:58:33Z
type: task
priority: 1
assignee: dlepage
---
# G69: Stop-to-resume flow keeps feedback panel (no recap)

Implement PRD stop behavior: no recap panel on Stop, keep feedback panel visible and greyed with latest values, primary action becomes Resume to continue same session.

## Acceptance Criteria

- Stopping a session leaves feedback panel visible with last metrics, visually greyed/disabled\n- No recap panel appears on Stop\n- Primary action switches to Resume and resumes the same session when clicked\n- Session state persists without losing metrics\n- Unit/UI tests cover stop-to-resume state

