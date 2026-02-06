---
id: cal-8fgg
status: closed
deps: []
links: []
created: 2026-02-06T05:10:05Z
type: task
priority: 2
assignee: dlepage
---
# Hide blocking reasons during recording

Blocking reasons text appears on the session screen even while a recording is active. This is distracting during live coaching.

## Acceptance Criteria

- Blocking reasons text is only visible when not recording.\n- SessionViewState exposes a bool for whether blocking reasons should render.\n- Tests cover the new view-state behavior.


## Notes

**2026-02-06T05:10:32Z**

swift test failed: ModuleCache permission error under ~/.cache/clang with MacOSX26.2 SDK and arm64-apple-macosx14.0 standard library load failure.
