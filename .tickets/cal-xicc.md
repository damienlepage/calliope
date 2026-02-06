---
id: cal-xicc
status: closed
deps: []
links: []
created: 2026-02-06T16:37:04Z
type: task
priority: 2
assignee: dlepage
tags: [long-session, storage, ui]
---
# G8: Add live storage guardrail for long sessions

Surface a storage safety signal during recording so multi-hour sessions don't silently fail due to low disk.

## Acceptance Criteria

- While recording, estimate available recording time based on current file growth and free disk space (or codec/format estimate if growth is unavailable).\n- Show a warning status in the live feedback panel (and compact overlay) when estimated remaining time falls below a threshold (ex: 30 minutes).\n- Do not show the warning when not recording.\n- Add unit coverage for the estimator/threshold logic.\n- No new dependencies.

