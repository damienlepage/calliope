#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE_CACHE_DIR="${ROOT_DIR}/.build/module-cache"
SWIFTPM_CACHE_DIR="${ROOT_DIR}/.build/swiftpm-cache"
LOCAL_HOME="${ROOT_DIR}/.swift-test-home"
XDG_CACHE_DIR="${LOCAL_HOME}/.cache"

mkdir -p "${MODULE_CACHE_DIR}" "${SWIFTPM_CACHE_DIR}" "${XDG_CACHE_DIR}"

export HOME="${LOCAL_HOME}"
export XDG_CACHE_HOME="${XDG_CACHE_DIR}"
export SWIFTPM_CACHE_PATH="${SWIFTPM_CACHE_DIR}"
export SWIFTPM_MODULECACHE_OVERRIDE="${MODULE_CACHE_DIR}"

exec swift test --disable-sandbox \
  -Xcc -fmodules-cache-path="${MODULE_CACHE_DIR}" \
  -Xswiftc -module-cache-path \
  -Xswiftc "${MODULE_CACHE_DIR}" \
  "$@"
