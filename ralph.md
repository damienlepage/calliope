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
1. Read PRD.md, goals.yaml, status.yaml, lessons-learned.yaml
2. Use Ticket (`tk`) to decide the best next step:
   - Run `tk ready` to see unblocked work.
   - If multiple are ready, prefer lowest priority number (highest priority), then pick the oldest ready ticket.
   - If none are ready, use `tk create` to generate the next batch of tasks from PRD.md and goals with clear acceptance criteria, priorities, and dependencies.
3. Pick ONE ready ticket, read it with `tk show <id>`, and complete it end-to-end.
4. Make minimal changes, update tests or add small verification steps.
5. Run `swift test` when feasible.
6. Update ticket status with `tk status <id> <status>` and note any new lessons.
7. Update goals/status only if meaningfully changed.
8. Commit all changes in the repository with the details of the iteration.

## Stopping Conditions
- No ready tickets and no clear next task.
- All goals are at target.
- Build is broken and needs human guidance.
- New permissions or risky changes are required.

## Task Selection Rules
- Prefer highest priority ready tickets.
- If any goals are BELOW_TARGET, prefer tickets that directly move those goals to AT_TARGET.
- If blocked, create or refine tickets with clear acceptance criteria.
- If tasks exceed one iteration, split into smaller tickets.

## Priority Scale
- 0: Blocking issues (build/run failures, privacy violations, critical regressions).
- 1: Core MVP capabilities (mic capture, real-time feedback, session UI).
- 2: Supporting UX flows (recordings, settings, permissions, storage access).
- 3: Quality improvements and polish (visual tweaks, copy, refactors).
- 4: Nice-to-have or experimental work.
