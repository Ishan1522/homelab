#!/usr/bin/env bash
# shellcheck disable=SC2029  # remote commands expand client-side on purpose
# Pull live config off the Proxmox host into snapshots/ and commit if anything drifted.
# Read-only on the server side. Safe to run any time.
#
#   PVE_HOST=root@my-pve STREAM_CTS="201 206" ./scripts/snapshot.sh
set -euo pipefail

PVE_HOST="${PVE_HOST:-root@CHANGEME-pve}"   # Proxmox host's Tailscale name
STREAM_CTS="${STREAM_CTS:-201 206}"         # containers running Sunshine
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SNAP="$REPO_ROOT/snapshots"

mkdir -p "$SNAP/pve/lxc" "$SNAP/pve/qemu" "$SNAP/host"

echo "==> LXC + VM configs"
rsync -a --delete "$PVE_HOST:/etc/pve/lxc/" "$SNAP/pve/lxc/"
rsync -a --delete "$PVE_HOST:/etc/pve/qemu-server/" "$SNAP/pve/qemu/"

echo "==> host files"
for f in /etc/fstab /usr/local/bin/gpu-switch /etc/network/interfaces; do
  if ssh "$PVE_HOST" "test -f $f"; then
    scp -q "$PVE_HOST:$f" "$SNAP/host/$(basename "$f")"
  else
    echo "   (skip: $f not found)"
  fi
done

echo "==> streaming containers: $STREAM_CTS"
for ct in $STREAM_CTS; do
  mkdir -p "$SNAP/ct$ct"
  for f in /usr/local/bin/pulse-start.sh \
           /etc/systemd/system/xfce-display.service \
           /etc/systemd/system/sunshine.service \
           /root/.config/sunshine/sunshine.conf; do
    tmp="/tmp/snap-$ct-$(basename "$f")"
    if ssh "$PVE_HOST" "pct pull $ct $f $tmp" 2>/dev/null; then
      scp -q "$PVE_HOST:$tmp" "$SNAP/ct$ct/$(basename "$f")"
      ssh "$PVE_HOST" "rm -f $tmp"
    else
      echo "   (ct$ct: no $f)"
    fi
  done
done

cd "$REPO_ROOT"
git add snapshots
if git diff --cached --quiet -- snapshots; then
  echo "==> no drift"
else
  git --no-pager diff --cached --stat -- snapshots
  git commit -q -m "snapshot: $(date -I)" -- snapshots
  echo "==> drift committed (git show to see it)"
fi
