---
id: cal-xbkj
status: closed
deps: []
links: []
created: 2026-02-06T07:38:00Z
type: task
priority: 2
assignee: dlepage
tags: [ui, session, ux]
---
# Session idle prompt hides when Start is blocked

When Start is disabled due to blocking reasons, hide the idle encouragement prompt so the user focuses on the blocking reason.

## Acceptance Criteria

- SessionViewState.shouldShowIdlePrompt is false when not recording and hasBlockingReasons is true.\n- Existing idle prompt remains visible when no blocking reasons exist.\n- SessionViewState tests updated to cover the blocked idle state.


## Notes

**2026-02-06T07:38:26Z**

swift test failed: ModuleCache permission error in /Users/dlepage/.cache/clang/ModuleCache (Operation not permitted)
