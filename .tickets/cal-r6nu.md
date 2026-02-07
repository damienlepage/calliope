---
id: cal-r6nu
status: closed
deps: []
links: []
created: 2026-02-07T07:54:46Z
type: task
priority: 2
assignee: dlepage
tags: [tests, session, recordings]
---
# End-to-end session flow smoke test

Add an integration-style test that exercises session start/stop and validates post-session recap + recording metadata.

## Acceptance Criteria

Test starts a session, simulates minimal audio/transcript updates, stops session, and asserts a recording item is persisted with expected duration/speaking metrics and recap values match metadata.


## Notes

**2026-02-07T07:58:58Z**

Added SessionFlowSmokeTests to cover start/stop summary + recap alignment. Ran ./scripts/swift-test.sh --filter SessionFlowSmokeTests.
