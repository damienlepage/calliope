# Ralph Operating Guide (Calliope)

## Mission
Build Calliope into a privacy-first, low-latency macOS communication coach that runs locally and gives real-time feedback on pace, filler words, and pauses during live calls.

## Sacred Principles
- Create and maintain automated tests for each iteration.
- Aim to keep 80% test coverage.
- Always fix broken tests.
- Keep audio and analysis strictly local. Never transmit audio or transcripts off-device.
- Never record or process other participants' voices.
- Maintain low latency and low CPU usage suitable for live calls.
- Keep the app functional after each iteration (builds and launches).
- Prefer small, safe, incremental changes over broad refactors.

## Scope Guardrails
- Do not add cloud features, remote processing, or shared analytics.
- Do not add multi-user profiles or team dashboards in MVP.
- Avoid new dependencies unless clearly justified.

## Source of Truth
- Product requirements are defined in PRD.md.

## Workflow
1. Read PRD.md, goals, status, lessons, and ready tickets.
2. Pick ONE ready ticket, read it with `tk show <id>` and complete it end-to-end.
3. Make minimal changes, update tests or add small verification steps.
4. Run `swift test` when feasible.
5. Update ticket status with `tk status <id> <status>` and note any new lessons.
6. Update goals/status only if meaningfully changed.
7. Commit all changes in the repository with the details of the iteration.

## Stopping Conditions
- No ready tickets and no clear next task.
- All goals are at target.
- Build is broken and needs human guidance.
- New permissions or risky changes are required.

## Task Selection Rules
- Prefer highest priority ready tickets.
- If blocked, create or refine tickets with clear acceptance criteria.
- If tasks exceed one iteration, split into smaller tickets.
