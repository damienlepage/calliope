---
id: cal-4z2m
status: closed
deps: []
links: []
created: 2026-02-06T18:10:00Z
type: task
priority: 2
assignee: dlepage
tags: [metadata, ui]
---
# G24: Clarify session title prompt with default preview

Improve session title entry so users understand what name will be saved when they skip or leave the field blank.

## Acceptance Criteria

- Session title prompt shows the default session title preview when the draft is empty.
- Helper text distinguishes between blank input (default title) vs. user-provided input (saved title), while preserving existing truncation warning.
- Saving with blank/whitespace input behaves the same as Skip (default metadata already written).
- Unit tests cover prompt helper text/preview states for blank input and long titles.

## Notes

