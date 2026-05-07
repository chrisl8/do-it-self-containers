#!/usr/bin/with-contenv bash
# Remove stale ipc-socket and lockfile left behind when qbittorrent was killed
# ungracefully (SIGKILL, OOM, hard reboot). Without this, qbittorrent v5.x sees
# the orphaned socket on startup, tries to hand off to the nonexistent prior
# instance, and exits silently with code 0 — s6 then restarts it in a loop.

set -e

QBT_DIR=/config/qBittorrent

for f in "$QBT_DIR/ipc-socket" "$QBT_DIR/lockfile"; do
    if [[ -e $f ]]; then
        echo "[custom-init] removing stale $f"
        rm -f "$f"
    fi
done
