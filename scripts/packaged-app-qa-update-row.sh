#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${script_dir}/.." && pwd)

release_dir="${repo_root}/release"
qa_report_path=""

if [[ "$#" -lt 8 ]]; then
  cat <<'USAGE' >&2
Usage:
  ./scripts/packaged-app-qa-update-row.sh "macOS Version" "Environment" "Machine" "Launches" "Permissions" "Session Flow" "Recordings Storage" "Notes" [qa_report_path]

Example:
  ./scripts/packaged-app-qa-update-row.sh "macOS 14 (Sonoma)" "Physical" "Apple Silicon, MacBookPro18,3" "Yes" "Yes" "Yes" "Yes" "Mic prompt OK"
USAGE
  exit 1
fi

macos_version="$1"
environment="$2"
machine="$3"
launches="$4"
permissions="$5"
session_flow="$6"
recordings_storage="$7"
notes="$8"
qa_report_path="${9:-}"

if [[ -z "${qa_report_path}" ]]; then
  qa_report_path=$(ls "${release_dir}"/QA-*.md 2>/dev/null | sort | tail -n 1 || true)
fi

if [[ -z "${qa_report_path}" ]]; then
  echo "No release QA report found. Run ./scripts/new-release-qa-report.sh first." >&2
  exit 1
fi

if [[ ! -f "${qa_report_path}" ]]; then
  echo "Release QA report not found at ${qa_report_path}" >&2
  exit 1
fi

python3 - "${qa_report_path}" "${macos_version}" "${environment}" "${machine}" "${launches}" "${permissions}" "${session_flow}" "${recordings_storage}" "${notes}" <<'PY'
import re
import sys

path = sys.argv[1]
macos_version = sys.argv[2]
environment = sys.argv[3]
machine = sys.argv[4]
launches = sys.argv[5]
permissions = sys.argv[6]
session_flow = sys.argv[7]
recordings_storage = sys.argv[8]
notes = sys.argv[9]

with open(path, "r", encoding="utf-8") as handle:
    contents = handle.read()

row_pattern = rf"^\|\s*{re.escape(macos_version)}\s*\|.*$"
new_row = f"| {macos_version} | {environment} | {machine} | {launches} | {permissions} | {session_flow} | {recordings_storage} | {notes} |"

if not re.search(row_pattern, contents, flags=re.MULTILINE):
    raise SystemExit(f"No packaged app verification row found for {macos_version} in {path}")

updated_contents = re.sub(row_pattern, new_row, contents, flags=re.MULTILINE)

with open(path, "w", encoding="utf-8") as handle:
    handle.write(updated_contents)
PY

printf 'Packaged app verification row updated: %s\n' "${qa_report_path}"
printf 'macOS version: %s\n' "${macos_version}"
