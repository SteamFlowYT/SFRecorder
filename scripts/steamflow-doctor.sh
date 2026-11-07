#!/usr/bin/env bash
# SteamFlow Recorder diagnostics (read-only; no sudo).
# SPDX-License-Identifier: GPL-3.0-only
set -u
OUT="$HOME/Videos/SFRecorder"
VENV="${XDG_DATA_HOME:-$HOME/.local/share}/sfrecorder/venv"
ENGINE="$HOME/.local/bin/sfrecorder"
HELPER="$HOME/.local/lib/sfrecorder/sfrecorder-grab"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/sfrecorder"
echo 'SteamFlow Recorder diagnostics (read-only)'
date -Iseconds 2>/dev/null || date
printf 'Architecture: %s | Kernel: %s\n' "$(uname -m)" "$(uname -r)"
python3 --version 2>&1 || true
if [ -x "$VENV/bin/python" ]; then
  "$VENV/bin/python" -m pip --version 2>&1 || echo '[WARN] pip missing from recorder virtual environment'
  "$VENV/bin/python" -c 'import openvr, PIL; print("[OK] dashboard modules available")' 2>&1 || echo '[WARN] Missing openvr or Pillow'
else
  echo '[WARN] Recorder virtual environment missing'
fi
if [ -x "$ENGINE" ]; then
  "$ENGINE" --version 2>&1 || true
  command -v ldd >/dev/null 2>&1 && ldd "$ENGINE" 2>&1 | grep 'not found' || true
else
  echo '[WARN] Recorder binary missing'
fi
if [ -x "$HELPER" ]; then
  getcap "$HELPER" 2>/dev/null || true
else
  echo '[WARN] Panel helper missing'
fi
systemctl --user is-active sfrecorder.service 2>&1 || true
if [ -d "$OUT" ]; then
  df -h "$OUT" 2>&1 || true
  find "$OUT" -maxdepth 1 -type f -name '*.mp4.part' -print 2>/dev/null || true
fi
for name in update.log last-recording.log; do
  if [ -f "$CACHE/$name" ]; then
    echo "--- Last 15 lines: $name ---"
    tail -n 15 "$CACHE/$name"
  fi
done
echo 'Done: no settings or recordings were changed.'
