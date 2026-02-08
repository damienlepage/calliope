---
id: cal-w7op
status: closed
deps: []
links: []
created: 2026-02-08T00:51:42Z
type: task
priority: 1
assignee: dlepage
---
# Add regression test for 203 WPM audio fixture

Add analysis regression coverage using Tests/Resources/sample-203wpm.wav to validate pace and speaking metrics.

## Acceptance Criteria

- New test loads Tests/Resources/sample-203wpm.wav and analyzes via AudioAnalyzer test helpers\n- Asserts ~29s duration, ~203 WPM within 10% tolerance\n- Asserts 0 pauses, 100% speaking time, 0 crutch words\n- Test passes with existing suite (swift test)

