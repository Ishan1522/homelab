#!/usr/bin/env bash
# SCAFFOLD-PLACEHOLDER: reference version written from notes, not your real script.
# Replace with your copy from snapshots/ct<ID>/pulse-start.sh.
#
# ExecStartPre for xfce-display.service. Two gotchas it handles:
#   1. PULSE_SERVER in the env makes pulseaudio refuse to autospawn, so unset it.
#   2. `pulseaudio --start` returns before the server is ready, so poll pactl.
set -euo pipefail
unset PULSE_SERVER

if pulseaudio --check 2>/dev/null; then exit 0; fi

pulseaudio --daemonize=yes --disable-shm --exit-idle-time=-1 \
  --load="module-native-protocol-unix auth-anonymous=1"

for _ in $(seq 1 50); do
  pactl info >/dev/null 2>&1 && exit 0
  sleep 0.2
done
echo "pulseaudio never became ready" >&2
exit 1
