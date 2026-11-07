#!/usr/bin/env bash
# Install / update SteamFlow Recorder on Steam Frame (GPL-3.0-only).
# Based on MWGIH/SFRecorder. Keeps existing recordings.
set -euo pipefail
REPO="https://github.com/SteamFlowYT/SFRecorder.git"
DEST="${STEAMFLOW_RECORDER_SOURCE:-$HOME/SteamFlowRecorder}"

if ! command -v git >/dev/null 2>&1; then
  echo 'ERROR: git is required on your Steam Frame.' >&2
  exit 1
fi
if [ -e "$DEST" ] && [ ! -d "$DEST/.git" ]; then
  echo "ERROR: $DEST already exists and is not a Git checkout. Nothing overwritten." >&2
  exit 1
fi

if [ ! -d "$DEST/.git" ]; then
  echo '==> Cloning SteamFlow Recorder'
  git clone --depth 1 --branch main -- "$REPO" "$DEST"
else
  ORIGIN="$(git -C "$DEST" remote get-url origin 2>/dev/null || true)"
  case "$ORIGIN" in
    "$REPO"|https://github.com/SteamFlowYT/SFRecorder|git@github.com:SteamFlowYT/SFRecorder.git) ;;
    *) echo "ERROR: $DEST is from a different repository: $ORIGIN" >&2; exit 1 ;;
  esac
  if [ -n "$(git -C "$DEST" status --porcelain)" ]; then
    echo "ERROR: $DEST has uncommitted changes. Back them up first." >&2
    exit 1
  fi
  echo '==> Updating SteamFlow Recorder source'
  git -C "$DEST" pull --ff-only
fi

if [ ! -f "$DEST/install.sh" ] || [ ! -f "$DEST/scripts/steamflow-venv.sh" ]; then
  echo 'ERROR: Fork installer files missing. Installation cancelled.' >&2
  exit 1
fi

echo '==> Installing SteamFlow Recorder'
echo '    Existing videos in ~/Videos/SFRecorder will be kept.'
bash "$DEST/install.sh"
echo '==> Done. Open the SteamFlow Recorder tab in SteamVR.'
