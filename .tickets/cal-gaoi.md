---
id: cal-gaoi
status: closed
deps: []
links: []
created: 2026-02-07T02:48:35Z
type: feature
priority: 2
assignee: dlepage
---
# G36: Add diagnostics export report

Create a privacy-safe diagnostics export (no audio or transcripts) that captures app/system state and preferences for troubleshooting.

## Acceptance Criteria

- Settings includes an Export Diagnostics button with helper text explaining it contains no audio or transcripts.\n- Export writes a JSON report to a Diagnostics subfolder under the recordings directory with a timestamped filename.\n- The report includes createdAt, app version/build, macOS version string, microphone + speech permission states, capture preferences (voice isolation, preferred input, max segment duration), recording retention preferences, and recordings count.\n- Export reveals the generated file in Finder.\n- Unit coverage verifies report encoding and writer output path/filename.

