---
id: cal-1zvp
status: closed
deps: []
links: []
created: 2026-02-07T08:24:00Z
type: task
priority: 1
assignee: dlepage
---
# Add end-to-end core flow smoke coverage

Create end-to-end unit smoke coverage for core user flows: start/stop session, post-session recap, recordings playback entry points, and settings edits persistence.

## Acceptance Criteria

- New test(s) cover start/stop session -> recap availability -> recordings list refresh and action availability\n- Settings edits persist and influence session/recordings flows (reuse existing stores)\n- Tests pass with swift test


## Notes

**2026-02-07T08:26:57Z**

Added CoreFlowEndToEndTests covering settings persistence, session flow, recordings refresh, and playback; ran ./scripts/swift-test.sh.
