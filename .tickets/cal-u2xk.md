---
id: cal-u2xk
status: closed
deps: []
links: []
created: 2026-02-04T06:05:00Z
type: task
priority: 2
assignee: dlepage
---
# Add int32 pause detector coverage

Add RMS support for int32 audio buffers in `PauseDetector` and cover it with a unit test.

## Acceptance Criteria

- `PauseDetector` handles `.pcmFormatInt32` buffers when computing RMS.
- Unit test validates pause detection behavior with int32 speech and silence buffers.

## Notes

**2026-02-04T06:12:00Z**

Added int32 RMS handling in `PauseDetector` and unit coverage for pause detection using int32 buffers.

**2026-02-04T06:14:00Z**

`swift test` failed due to Swift toolchain/SDK mismatch and SwiftShims cache permission errors (same issue noted in prior lessons).
