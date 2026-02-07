---
id: cal-cru1
status: closed
deps: []
links: []
created: 2026-02-07T04:19:18Z
type: task
priority: 2
assignee: dlepage
tags: [accuracy, tests, crutch]
---
# G41: Regression test for crutch count stability across updates

Ensure live crutch counts in AudioAnalyzer match the final summary when multiple transcription updates arrive during a session.

## Acceptance Criteria

1. New unit test sends multiple transcripts during recording.
2. Test asserts final AnalysisSummary crutch counts and totalWords reflect the latest transcript values.
3. Tests pass.
