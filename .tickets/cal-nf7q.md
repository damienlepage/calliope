---
id: cal-nf7q
status: closed
deps: []
links: []
created: 2026-02-06T05:16:50Z
type: task
priority: 2
assignee: dlepage
tags: [ui, session]
---
# Display session duration with hours for long sessions

Ensure elapsed time formatting stays readable for sessions lasting 1 hour or more by including hours in the duration text.

## Acceptance Criteria

- SessionDurationFormatter outputs HH:MM:SS when duration is >= 3600 seconds.\n- Durations under 1 hour still display MM:SS.\n- Tests cover both under-hour and multi-hour formatting.


## Notes

**2026-02-06T05:17:16Z**

swift test failed: SwiftPM cache paths not writable and ModuleCache permission error under ~/.cache/clang; unable to load arm64-apple-macosx14.0 stdlib with MacOSX26.2 SDK.
