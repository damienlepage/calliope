#!/usr/bin/env bash
set -euo pipefail

NTFY_TOPIC=ralph-dlepage-calliope
STATE_DIR=".ralph-state"
LOG_DIR="$STATE_DIR/logs"
SESS_DIR="$STATE_DIR/sessions"
STOP_FILE="$STATE_DIR/STOP"
PID_FILE="$STATE_DIR/ralph.pid"

ITERATION_DELAY="${ITERATION_DELAY:-60}"
AGENT_CMD="${AGENT_CMD:-codex exec --full-auto}"
MAX_ITERATIONS="${MAX_ITERATIONS:-50}"
MAX_TEST_ATTEMPTS="${MAX_TEST_ATTEMPTS:-10}"

mkdir -p "$LOG_DIR" "$SESS_DIR"

log() {
  printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_DIR/ralph.log"
}

notify() {
  if [[ -n "${NTFY_TOPIC:-}" ]]; then
    curl -s -d "$*" "https://ntfy.sh/${NTFY_TOPIC}" >/dev/null || true
  fi
}

read_status_value() {
  local key="$1"
  awk -F': ' -v k="$key" '$1==k {print $2}' "$STATE_DIR/status.yaml"
}

write_status() {
  local iteration="$1"
  local outcome="$2"
  local successes="$3"
  local failures="$4"

  cat > "$STATE_DIR/status.yaml" <<EOF_STATUS
iteration: ${iteration}
last_run: "$(date '+%Y-%m-%dT%H:%M:%S')"
last_outcome: "${outcome}"
consecutive_successes: ${successes}
consecutive_failures: ${failures}
active_task_ids: []
notes: "Updated by ralph.sh"
EOF_STATUS
}

goals_achieved() {
  if grep -q 'status: "BELOW_TARGET"' "$STATE_DIR/goals.yaml"; then
    return 1
  fi
  return 0
}

build_prompt() {
  local session_file="$1"
  {
    echo "You are Ralph, an autonomous dev agent for the Calliope repo."
    echo "Follow ralph.md precisely."
    echo
    echo "## Operating Guide"
    cat ralph.md
    echo
    echo "## Product Requirements (PRD.md)"
    cat PRD.md
    echo
    echo "## Goals"
    cat "$STATE_DIR/goals.yaml"
    echo
    echo "## Status"
    cat "$STATE_DIR/status.yaml"
    echo
    echo "## Lessons Learned"
    cat "$STATE_DIR/lessons-learned.yaml"
    echo
    echo "## Ready Tickets"
    tk ready || true
    echo
    echo "## Git Status"
    git status -sb
    echo
    echo "## Recent Commits"
    git --no-pager log -5 --oneline || true
    echo
    echo "## Instructions"
    echo "- Complete exactly ONE ready ticket."
    echo "- If no ready tickets, create or refine tickets based on PRD.md."
    echo "- Keep changes minimal and safe."
    echo "- Update tickets and goals if needed."
    echo "- Run 'swift build' if reasonable."
  } > "$session_file"
}

run_iteration() {
  local iteration="$1"
  local session_file="$SESS_DIR/session-${iteration}.md"

  build_prompt "$session_file"

  log "Starting iteration ${iteration}"
  if echo "$(cat "$session_file")" | eval "$AGENT_CMD"; then
    log "Iteration ${iteration} completed"
  else
    log "Iteration ${iteration} failed"
    return 1
  fi

  local test_attempt=0
  local tests_fixed="false"
  while true; do
    test_attempt=$((test_attempt + 1))
    local test_log="$LOG_DIR/tests-iter-${iteration}-attempt-${test_attempt}.log"
    local test_session="$SESS_DIR/test-session-${iteration}-${test_attempt}.md"

    log "Running swift test (iteration ${iteration}, attempt ${test_attempt})"
    set +e
    swift test 2>&1 | tee "$test_log"
    local test_status=${PIPESTATUS[0]}
    set -e

    if [[ "$test_status" -eq 0 ]]; then
      log "swift test passed (iteration ${iteration}, attempt ${test_attempt})"
      if [[ "$tests_fixed" == "true" ]]; then
        if ! git diff --quiet; then
          git add -A
          git commit -m "fix tests"
          log "Committed test fixes with message: fix tests"
        else
          log "No changes to commit after fixing tests"
        fi
      fi
      return 0
    fi

    if [[ "$test_attempt" -ge "$MAX_TEST_ATTEMPTS" ]]; then
      log "swift test still failing after ${MAX_TEST_ATTEMPTS} attempts"
      return 1
    fi

    {
      echo "You are Ralph, an autonomous dev agent for the Calliope repo."
      echo
      echo "## Test Output"
      cat "$test_log"
      echo
      echo "## Instructions"
      echo "- Fix the failing tests shown above."
      echo "- Make minimal, safe changes."
      echo "- DO NOT commit changes."
    } > "$test_session"

    log "Sending failing test output to agent (iteration ${iteration}, attempt ${test_attempt})"
    if ! echo "$(cat "$test_session")" | eval "$AGENT_CMD"; then
      log "Agent failed while fixing tests (iteration ${iteration}, attempt ${test_attempt})"
      return 1
    fi
    tests_fixed="true"
  done
}

main_loop() {
  local single_iteration="${1:-false}"
  local start_iteration
  start_iteration=$(read_status_value "iteration")
  if [[ -z "$start_iteration" ]]; then
    start_iteration=0
  fi
  local max_iteration=$((start_iteration + MAX_ITERATIONS))

  while true; do
    if [[ -f "$STOP_FILE" ]]; then
      log "STOP file detected, exiting"
      rm -f "$STOP_FILE"
      exit 0
    fi

    if goals_achieved; then
      log "All goals achieved, exiting"
      exit 0
    fi

    local current_iteration
    current_iteration=$(read_status_value "iteration")
    if [[ -z "$current_iteration" ]]; then
      current_iteration=0
    fi

    local next_iteration=$((current_iteration + 1))
    if [[ "$next_iteration" -gt "$max_iteration" ]]; then
      log "Reached max iterations (${MAX_ITERATIONS}) from start (${start_iteration}), exiting"
      exit 0
    fi

    if run_iteration "$next_iteration"; then
      local successes
      successes=$(read_status_value "consecutive_successes")
      successes=$((successes + 1))
      write_status "$next_iteration" "SUCCESS" "$successes" 0
      notify "Ralph iteration ${next_iteration} succeeded."
    else
      local failures
      failures=$(read_status_value "consecutive_failures")
      failures=$((failures + 1))
      write_status "$next_iteration" "FAILURE" 0 "$failures"
      notify "Ralph iteration ${next_iteration} failed."
      log "Iteration failure detected, stopping main loop"
      exit 1
    fi

    if [[ "$single_iteration" == "true" ]]; then
      log "Single-iteration mode complete"
      exit 0
    fi

    sleep "$ITERATION_DELAY"
  done
}

if [[ "${1:-}" == "--single-iteration" ]]; then
  main_loop "true"
else
  main_loop "false"
fi
