---
id: cal-7sgv
status: closed
deps: []
links: []
created: 2026-02-07T18:34:08Z
type: task
priority: 1
assignee: dlepage
---
# G60: Pace visualization shows target zone

Make the pace display clearly communicate the active target zone range at a glance in live feedback surfaces.

## Acceptance Criteria

Pace display includes a visual target zone indicator aligned with the active coaching profile min/max range.\nIndicator is visible in the compact overlay and main feedback panel.\nAccessibility labels/values reflect the target zone context.


## Notes

**2026-02-07T18:36:14Z**

Added shared PaceRangeBar view, reused in FeedbackPanel and CompactFeedbackOverlay (new bar in overlay). Updated target range text to include 'Target' label; refreshed PaceFeedback tests. Ran ./scripts/swift-test.sh.
