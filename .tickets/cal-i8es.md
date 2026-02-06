---
id: cal-i8es
status: closed
deps: []
links: []
created: 2026-02-06T07:24:56Z
type: task
priority: 1
assignee: dlepage
tags: [ui, privacy]
---
# Session screen shows blocking reasons when Start is disabled

When Start is disabled due to privacy/mic eligibility, the session screen should surface the blocking reason text so the user knows what to fix.

## Acceptance Criteria

- When recording is not active and Start is disabled, the session screen displays the blocking reason text.\n- When recording is active, blocking reasons are not shown.\n- SessionViewState tests cover the blocked idle state.


## Notes

**2026-02-06T07:25:29Z**

Updated SessionViewState to show blocking reasons when Start disabled; added test for blocked idle state. swift test failed due to sandbox cache permission (ModuleCache not writable).
