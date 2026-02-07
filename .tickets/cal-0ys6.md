---
id: cal-0ys6
status: closed
deps: []
links: []
created: 2026-02-07T19:09:50Z
type: task
priority: 1
assignee: dlepage
tags: [release, qa, packaging]
---
# G57: Add packaged app verification preflight helper

Add a helper script to capture local macOS version, hardware model, and Calliope app bundle info for packaged app verification. The script should optionally prefill the current release QA report with the machine metadata and return a reminder if dist/Calliope.app is missing.

## Acceptance Criteria

- New script in scripts/ that prints macOS version + hardware model + CPU arch and packaged app version/build if dist/Calliope.app exists.\n- Script can update the most recent release/QA-YYYY-MM-DD.md or a provided path with the machine metadata section.\n- release/README.md mentions the helper.\n- Unit test verifies the script exists and is referenced in release/README.md.

