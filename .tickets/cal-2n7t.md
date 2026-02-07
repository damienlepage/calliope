---
id: cal-2n7t
status: closed
deps: []
links: []
created: 2026-02-07T08:10:45Z
type: task
priority: 1
assignee: dlepage
---
# Add end-to-end core session flow validation

Create deterministic end-to-end coverage for starting/stopping a session and ensuring post-session recap + optional title prompt state is consistent.

## Acceptance Criteria

- A new XCTest (or suite) validates session start -> active recording -> stop -> recap visibility with key stats populated.\n- Test verifies optional title prompt does not block recap.\n- Uses existing model/coordinator state without requiring UI automation.\n- Test runs under swift test.

