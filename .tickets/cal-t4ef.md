---
id: cal-t4ef
status: closed
deps: []
links: []
created: 2026-02-07T20:21:36Z
type: task
priority: 1
assignee: dlepage
---
# G57: Verify packaged app on macOS 15 (Sequoia)

Run packaged app QA on macOS 15 and document results.

## Acceptance Criteria

- Run ./scripts/packaged-app-qa-preflight.sh on a macOS 15 machine with dist/Calliope.app available\n- Launch dist/Calliope.app and complete the packaged app verification steps (launch, permissions, session flow, recordings storage)\n- Update the packaged app verification row for macOS 15 in the latest release QA report under release/ with Yes/No and notes\n- Add any blockers or VM limitations to the notes


## Notes

**2026-02-07T20:22:30Z**

Duplicate of cal-3wcf (macOS 15 packaged app verification) which is blocked on hardware access via cal-b1yg. Closing to avoid duplicate tracking.
