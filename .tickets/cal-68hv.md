---
id: cal-68hv
status: closed
deps: [cal-aygb]
links: []
created: 2026-02-04T04:39:28Z
type: task
priority: 2
assignee: dlepage
---
# MVP: Crutch word detection prototype

Wire a simple speech transcription pipeline (on-device) and count a small list of filler words. Success: count increments for known fillers in a short test recording.


## Notes

**2026-02-04T05:25:06Z**

Implemented crutch word detector tokenization + phrase matching, wired counts into AudioAnalyzer, and added XCTest coverage. swift build failed in this environment due to Swift toolchain/SDK mismatch and cache permission errors.
