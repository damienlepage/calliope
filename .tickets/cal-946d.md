---
id: cal-946d
status: closed
deps: []
links: []
created: 2026-02-07T23:58:38Z
type: task
priority: 2
assignee: dlepage
---
# G70: Audio fixture regression test for 203 WPM sample

Add analysis regression test using Tests/Resources/sample-203wpm.wav to validate metrics within tolerance.

## Acceptance Criteria

- New test runs audio fixture through analysis pipeline\n- Asserts duration ~29s within 10% tolerance\n- Asserts WPM ~203 within 10% tolerance\n- Asserts 0 pauses, 100% speaking time, 0 crutch words\n- Test is deterministic and passes with existing pipelines

