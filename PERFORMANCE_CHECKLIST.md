# Performance Validation Checklist

This checklist verifies that Calliope stays low-latency and low-impact during live calls.
Run it before releases and after changes to audio capture, analysis, or UI rendering.

## Targets
- CPU (Activity Monitor, Calliope process)
  - Apple Silicon: 3-8% average while recording, <= 15% peaks under normal speech
  - Intel: 5-12% average while recording, <= 20% peaks under normal speech
- Energy Impact: should remain "Low" or briefly "Medium" only during spikes
- Memory: no sustained growth after 10 minutes of recording (drift <= 20 MB)
- Latency: in-app processing latency should remain "OK" (no sustained "High")

## Checklist
1. Baseline idle
   - Launch Calliope and remain on the Session screen for 2 minutes without recording.
   - Record CPU %, memory footprint, and Energy Impact in Activity Monitor.

2. Steady-state recording
   - Start recording and speak normally for 5 minutes.
   - Confirm CPU and Energy Impact are within target ranges.
   - Ensure in-app latency status stays "OK" and no UI jank is visible.

3. Short stress burst
   - Speak continuously for 2 minutes at a faster pace.
   - Note peak CPU and Energy Impact; confirm no sustained "High" latency.

4. Memory drift check
   - Keep recording for 10 minutes, then compare memory to the 1-minute mark.
   - Verify drift stays within 20 MB and stabilizes.

5. Instruments baseline capture
   - Open Instruments -> Time Profiler and Energy Log.
   - Record 30 seconds idle + 2 minutes recording in one session.
   - Verify no single hot path dominates CPU and audio-related threads are not blocked.

6. Hardware variance guidance
   - Repeat steps 2-5 on at least one Apple Silicon and one Intel machine.
   - Intel is expected to be ~1.5x CPU vs Apple Silicon for the same workload.

7. Document results
   - Record the date, machine, macOS version, mic device, and results in release notes or testing logs.

## Troubleshooting Tips
- If CPU spikes:
  - Verify sample rate and buffer sizes are unchanged.
  - Check that analysis cadence has not increased.
- If Energy Impact rises:
  - Confirm display refresh or animations are not running while minimized.
- If latency flips to "High":
  - Re-check input device selection and background CPU load.
