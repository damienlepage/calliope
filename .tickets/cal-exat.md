---
id: cal-exat
status: closed
deps: []
links: []
created: 2026-02-06T18:58:19Z
type: task
priority: 1
assignee: dlepage
---
# G20: Apply per-app profiles based on frontmost app

Detect the frontmost app bundle identifier while recording and apply matching per-app feedback profile to analysis preferences.

## Acceptance Criteria

- Frontmost app bundle identifier is observed and normalized during recording.\n- If a matching per-app profile exists, analysis preferences (pace min/max, pause threshold, crutch words) are updated to profile values; otherwise defaults remain.\n- Active app identifier and resolved profile (if any) are exposed for UI use.\n- Unit tests cover profile selection and fallback behavior.


## Notes

**2026-02-06T19:02:19Z**

Implemented active per-app preferences resolver + frontmost app monitor with tests. swift test failed due to ModuleCache permission error under /Users/dlepage/.cache/clang/ModuleCache.
