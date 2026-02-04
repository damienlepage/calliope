#!/usr/bin/env bash
set -euo pipefail

STATE_DIR=".ralph-state"
LOG_DIR="$STATE_DIR/logs"
STOP_FILE="$STATE_DIR/STOP"
PID_FILE="$STATE_DIR/ralph.pid"

start() {
  if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Ralph already running (pid $(cat "$PID_FILE"))."
    exit 0
  fi

  rm -f "$STOP_FILE"
  nohup ./ralph.sh > "$LOG_DIR/ralph-output.log" 2>&1 &
  echo $! > "$PID_FILE"
  echo "Started Ralph (pid $(cat "$PID_FILE"))."
}

stop() {
  if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    touch "$STOP_FILE"
    echo "Stop requested."
  else
    echo "Ralph is not running."
  fi
}

status() {
  if [[ -f "$PID_FILE" ]] && ps -p "$(cat "$PID_FILE")" >/dev/null 2>&1; then
    echo "Ralph running (pid $(cat "$PID_FILE"))."
  else
    echo "Ralph not running."
  fi
}

logs() {
  tail -n 200 "$LOG_DIR/ralph-output.log"
}

sessions() {
  ls -1 "$STATE_DIR/sessions" || true
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  logs) logs ;;
  sessions) sessions ;;
  *)
    echo "Usage: $0 {start|stop|status|logs|sessions}"
    exit 1
    ;;
esac
