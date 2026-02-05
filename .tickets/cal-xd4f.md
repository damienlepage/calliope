---
id: cal-xd4f
status: closed
deps: []
links: []
created: 2026-02-05T00:00:00Z
type: task
priority: 2
assignee: dlepage
---
# Remove headset confirmation gate for recording eligibility

Allow recording eligibility to rely only on mic permission and disclosure acceptance. The UI should no longer require a headset confirmation toggle.

## Acceptance Criteria
- Recording eligibility no longer blocks on headset confirmation.
- ContentView removes headset confirmation toggle and related messaging.
- Tests cover updated eligibility and guardrail behavior.

## Notes

**2026-02-05T00:00:00Z**

Removed headset confirmation from PrivacyGuardrails/RecordingEligibility, updated UI, and adjusted tests.
