---
id: cal-llgp
status: closed
deps: []
links: []
created: 2026-02-07T04:27:03Z
type: task
priority: 1
assignee: dlepage
tags: [accuracy, tests]
---
# Add pace accuracy regression coverage

Add deterministic regression coverage to validate pace min/max/average WPM calculations against known elapsed times and transcript word counts during live analysis.

## Acceptance Criteria

1. New unit test drives AudioAnalyzer with controlled timestamps and transcripts to yield known WPM values. 2. Test asserts summary pace stats (min/max/average WPM) and totalWords match expected values. 3. Tests pass.

