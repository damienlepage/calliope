---
id: cal-md24
status: closed
deps: []
links: []
created: 2026-02-06T23:03:39Z
type: feature
priority: 2
assignee: dlepage
tags: [metadata, recordings, robustness]
---
# Normalize session metadata dates for robustness

Harden session metadata handling by validating createdAt timestamps and normalizing them against inferred session dates so recordings sort and display consistently.

## Acceptance Criteria

- RecordingManager normalizes metadata createdAt when it is missing or clearly invalid (e.g., far future/zero), preferring the inferred date from the filename.
- Normalized metadata is persisted so future reads are consistent.
- Backfill logic corrects invalid createdAt values (not just missing ones).
- Unit tests cover invalid/future createdAt normalization and persistence.
- No network or cloud storage behavior is added.
