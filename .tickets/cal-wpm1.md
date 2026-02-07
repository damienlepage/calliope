---
id: cal-wpm1
status: closed
deps: []
links: []
created: 2026-02-07T04:18:48Z
type: task
priority: 1
assignee: dlepage
tags: [accuracy, tests, pace]
---
# G41: Regression test for pace summary accuracy

Add deterministic coverage to ensure pace WPM stats (average/min/max/total words) align with transcript word counts and elapsed time when recording stops.

## Acceptance Criteria

1. New unit test drives AudioAnalyzer with a controlled clock and multiple transcripts.
2. Test asserts AnalysisSummary.pace.averageWPM/minWPM/maxWPM and totalWords match expected values.
3. Tests pass.
