#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "${script_dir}/.." && pwd)

template_path="${repo_root}/RELEASE_QA_TEMPLATE.md"
release_dir="${repo_root}/release"
date_stamp=$(date +%Y-%m-%d)
report_path="${release_dir}/QA-${date_stamp}.md"

if [[ ! -f "${template_path}" ]]; then
  echo "Release QA template not found at ${template_path}" >&2
  exit 1
fi

mkdir -p "${release_dir}"

if [[ -e "${report_path}" ]]; then
  echo "Report already exists: ${report_path}" >&2
  exit 1
fi

cp "${template_path}" "${report_path}"

echo "${report_path}"
