---
id: cal-5ncl
status: closed
deps: []
links: []
created: 2026-02-07T20:21:28Z
type: task
priority: 1
assignee: dlepage
---
# G57: Verify packaged app on macOS 13 (Ventura)

Run packaged app QA on macOS 13 and document results.

## Acceptance Criteria

- Run ./scripts/packaged-app-qa-preflight.sh on a macOS 13 machine with dist/Calliope.app available\n- Launch dist/Calliope.app and complete the packaged app verification steps (launch, permissions, session flow, recordings storage)\n- Update the packaged app verification row for macOS 13 in the latest release QA report under release/ with Yes/No and notes\n- Add any blockers or VM limitations to the notes


## Notes

**2026-02-07T20:22:19Z**

Duplicate of cal-2hq5 (macOS 13 packaged app verification) which is already blocked on hardware access via cal-b1yg. Closing to avoid duplicate tracking.
