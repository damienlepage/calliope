---
id: cal-fb29
status: closed
deps: []
links: []
created: 2026-02-06T05:13:44Z
type: task
priority: 2
assignee: dlepage
tags: [ui, overlay]
---
# Hide compact overlay when idle

Ensure the compact feedback overlay only appears during active recording to keep the idle UI calm and session-focused.

## Acceptance Criteria

- Overlay does not render when recording is stopped, even if toggle is enabled.\n- Overlay renders when recording is active and toggle is enabled.\n- Tests updated or added to cover visibility rules.


## Notes

**2026-02-06T05:14:12Z**

swift test failed: SwiftPM/clang cache not writable (ModuleCache) and SDK mismatch (MacOSX26.2 vs arm64-apple-macosx14.0).
