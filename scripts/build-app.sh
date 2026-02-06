#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Calliope"
BUILD_DIR="${ROOT_DIR}/.build/release"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
INFO_TEMPLATE="${ROOT_DIR}/scripts/app/Info.plist"

if [[ ! -f "${INFO_TEMPLATE}" ]]; then
  echo "Missing Info.plist template at ${INFO_TEMPLATE}" >&2
  exit 1
fi

swift build -c release --package-path "${ROOT_DIR}"

if [[ ! -x "${BUILD_DIR}/${APP_NAME}" ]]; then
  echo "Release binary not found at ${BUILD_DIR}/${APP_NAME}" >&2
  exit 1
fi

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
cp "${INFO_TEMPLATE}" "${CONTENTS_DIR}/Info.plist"

echo "App bundle created at ${APP_DIR}"
