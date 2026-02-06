---
id: cal-kg2p
status: ready
deps: []
links: []
created: 2026-02-06T17:10:10Z
type: task
priority: 2
assignee: dlepage
tags: [performance, diagnostics]
---
# G25: Add performance/energy validation checklist and diagnostics surfacing

Validate low CPU/energy impact with a lightweight in-app diagnostics summary and documented guidance.

## Acceptance Criteria

- Settings includes a concise diagnostics section that explains how to validate CPU/energy usage.
- Surface current processing utilization average/peak in Settings while recording.
- Provide a short guardrail checklist (e.g., close heavy apps, use headset) without adding new dependencies.
- Add unit tests covering diagnostics formatting logic.
