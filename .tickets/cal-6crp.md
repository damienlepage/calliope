---
id: cal-6crp
status: closed
deps: []
links: []
created: 2026-02-04T07:32:45Z
type: task
priority: 2
assignee: dlepage
---
# Ensure RecordingManager recreates missing recordings directory

Recreate the CalliopeRecordings folder on access if it was deleted so local storage remains reliable.

## Acceptance Criteria

- When recordings directory is missing, getAllRecordings recreates it and returns an empty list\n- When recordings directory is missing, getNewRecordingURL recreates it before returning a URL\n- Add unit coverage for the missing-directory scenario


## Notes

**2026-02-04T07:33:31Z**

Added directory recreation logic and tests. swift test failed due to SwiftPM cache permission and SDK/toolchain mismatch (see session output).
