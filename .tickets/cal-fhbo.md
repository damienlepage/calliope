---
id: cal-fhbo
status: closed
deps: []
links: []
created: 2026-02-06T21:39:49Z
type: feature
priority: 1
assignee: dlepage
---
# G23: Track speaking time and speaking turns in analysis summaries

Add speaking-activity tracking to the analysis pipeline so each session records total speaking time and number of speaking turns (speech segments). Persist these metrics in AnalysisSummary and recording metadata for long sessions.

## Acceptance Criteria

- AnalysisSummary includes speakingTimeSeconds and speakingTurnCount (or equivalent) persisted to JSON with versioned decoding defaults.\n- AudioAnalyzer (or a new tracker) derives speaking segments from existing RMS/pause detection and accumulates speaking time + turns only while recording.\n- Unit tests cover tracker behavior for alternating speech/silence and ensure summary encoding/decoding remains backward compatible.


## Notes

**2026-02-06T21:42:45Z**

Implemented speaking activity tracker + summary fields; added speaking activity unit tests and summary decode defaults. Ran ./scripts/swift-test.sh.
