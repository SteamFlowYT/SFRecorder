#!/usr/bin/env bash
# SteamFlow Recorder - recover a broken user-local Python venv without sudo.
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
if [ "$#" -ne 1 ]; then
  printf 'Usage: %s /path/to/venv\n' "$0" >&2
  exit 2
fi
VENV="$1"
PY="$VENV/bin/python"
if ! command -v python3 >/dev/null 2>&1; then
  echo 'ERROR: python3 is unavailable. Check SteamOS Python.' >&2
  exit 1
fi
if [ ! -x "$PY" ]; then
  echo '==> Creating user-local Python environment'
  python3 -m venv --without-pip "$VENV" || {
    echo 'ERROR: Python venv support is unavailable.' >&2
    exit 1
  }
fi
if "$PY" -m pip --version >/dev/null 2>&1; then
  echo '==> Python pip is healthy'
  exit 0
fi
echo '==> Restoring missing pip in the SFRecorder environment'
if "$PY" -m ensurepip --upgrade --default-pip >/dev/null 2>&1 && "$PY" -m pip --version >/dev/null 2>&1; then
  echo '==> pip restored using Python ensurepip'
  exit 0
fi
echo '==> ensurepip unavailable: downloading the official PyPA bootstrap script'
command -v curl >/dev/null 2>&1 || { echo 'ERROR: curl is required for pip recovery' >&2; exit 1; }
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error --retry 2 --connect-timeout 15 --max-time 90 --output "$TMP/get-pip.py" https://bootstrap.pypa.io/get-pip.py
[ -s "$TMP/get-pip.py" ] || { echo 'ERROR: downloaded get-pip.py is empty' >&2; exit 1; }
"$PY" "$TMP/get-pip.py" --disable-pip-version-check || {
  echo 'ERROR: pip bootstrapping failed; no recordings were touched.' >&2
  exit 1
}
"$PY" -m pip --version >/dev/null 2>&1 || { echo 'ERROR: pip still cannot import after recovery.' >&2; exit 1; }
echo '==> pip restored in the user-local venv'
