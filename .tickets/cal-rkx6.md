---
id: cal-rkx6
status: closed
deps: []
links: []
created: 2026-02-07T06:00:59Z
type: task
priority: 2
assignee: dlepage
---
# Accessibility: VoiceOver labels for session feedback

Audit SessionView and feedback surfaces to ensure VoiceOver reads live metrics and controls clearly.

## Acceptance Criteria

- VoiceOver reads pace, crutch words, pauses, speaking time, input level, and elapsed time with concise label + value text.\n- Session status, capture recovery banners, and route warnings expose accessibility labels/values without relying on color.\n- Start/Stop, CC toggle, coaching profile picker, and post-session action buttons announce meaningful labels and hints.\n- Add/adjust automated coverage for any new accessibility formatting or helper logic.


## Notes

**2026-02-07T06:03:03Z**

swift test failed due to ModuleCache permission errors under ~/.cache/clang and SwiftPM cache warnings.
