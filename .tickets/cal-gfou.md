---
id: cal-gfou
status: closed
deps: []
links: []
created: 2026-02-07T19:13:56Z
type: task
priority: 1
assignee: dlepage
tags: [release, qa, packaging]
---
# G57: Add QA helper to update packaged app verification row

Provide a helper script to update the per-macOS packaged app verification table row in the release QA report.

## Acceptance Criteria

- New script updates the Packaged App Verification table row for a specified macOS version in the latest QA report (or provided path).\n- Script fails with a clear message when the report is missing.\n- Release README mentions the new helper.\n- Unit test asserts the new helper is referenced.

