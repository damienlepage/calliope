---
id: cal-wjgj
status: closed
deps: []
links: []
created: 2026-02-06T07:10:37Z
type: task
priority: 2
assignee: dlepage
tags: [ui, session, ux]
---
# Session error state: hide idle prompt

Avoid showing the idle encouragement prompt when session status is error so the user focuses on the error state.

## Acceptance Criteria

- When status is error and not recording, SessionViewState.shouldShowIdlePrompt is false.\n- Error state still shows title, status, device selection message, and blocking reasons.\n- SessionViewState tests updated accordingly.


## Notes

**2026-02-06T07:11:09Z**

swift test failed: ModuleCache permission error in /Users/dlepage/.cache/clang/ModuleCache
