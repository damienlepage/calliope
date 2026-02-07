---
id: cal-hv7w
status: closed
deps: []
links: []
created: 2026-02-07T04:13:44Z
type: task
priority: 1
assignee: dlepage
tags: [accuracy, tests]
---
# Validate crutch stats alignment in summaries

Add regression coverage to ensure live crutch counts and total words are preserved in AnalysisSummary on stop (G41).

## Acceptance Criteria

1. New unit test exercises AudioAnalyzer while recording and verifies AnalysisSummary.crutchWords.totalCount and counts match live crutch detection. 2. Test verifies AnalysisSummary.pace.totalWords matches transcript word count. 3. Tests pass.

