---
id: cal-xaw5
status: closed
deps: []
links: []
created: 2026-02-07T21:25:38Z
type: bug
priority: 1
assignee: dlepage
tags: [audio, voice-detection]
---
# G62: Fix voice detection on built-in mic

Built-in mic currently fails voice detection while Bluetooth works. Identify root cause and ensure parity across device types, including mid-session switches.

## Acceptance Criteria

- Voice detection (speech activity / speaking-time tracking) works on built-in mic and Bluetooth devices.
- Switching input devices mid-session preserves voice detection without requiring restart.
- Unit coverage added for device-switch detection path or audio route change handling as feasible.

