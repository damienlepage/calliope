---
id: cal-bu2j
status: closed
deps: []
links: []
created: 2026-02-06T08:22:20Z
type: task
priority: 1
assignee: dlepage
tags: [ui, privacy, ux]
---
# Trim Session screen to PRD minimalism

Reduce non-session UI on Session screen; ensure permission/device details live in Settings.

## Acceptance Criteria

Session view shows only idle prompt + Start when idle; recording shows live feedback panel, status, and Start/Stop control. Device selection messages, microphone/backend status, and other setup details are removed from Session view. No permission recovery actions on Session screen.


## Notes

**2026-02-06T08:23:05Z**

Removed device/backend status lines from Session view to match PRD minimalism; updated SessionViewState tests. swift test fails due to ModuleCache permission errors under /Users/dlepage/.cache/clang/ModuleCache.
