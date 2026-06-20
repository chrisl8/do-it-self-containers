#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Seed LazyLibrarian's persistent storage paths on a fresh install.
#
# The LSIO image leaves ebook_dir unset, and a hand-set value of /books lived
# only in the container's ephemeral writable layer -- so every recreate (image
# update, module re-render) silently destroyed all downloaded books. These
# defaults point the ebook and download dirs at the real /media/arr bind mount,
# so a rebuilt container keeps its library.
#
# A key is filled in only when it is absent or empty, so any path the user
# later sets in the LazyLibrarian web UI is preserved across restarts and is
# never clobbered.
set -e

# This dir is only mounted into LazyLibrarian, but stay defensive in case the
# init dir is ever shared with another LSIO app.
[[ -d /app/lazylibrarian ]] || exit 0

CONFIG=/config/config.ini

set_default() {
    local key="$1" val="$2"
    # Already has a non-empty value -> respect the user's choice, leave it be.
    if [[ -f "$CONFIG" ]] && grep -qE "^${key}[[:space:]]*=[[:space:]]*[^[:space:]]" "$CONFIG"; then
        return
    fi
    # Ensure the file and its [GENERAL] section exist before inserting.
    [[ -f "$CONFIG" ]] || printf '[GENERAL]\n' >"$CONFIG"
    grep -qE '^\[GENERAL\]' "$CONFIG" || sed -i '1i [GENERAL]' "$CONFIG"
    if grep -qE "^${key}[[:space:]]*=" "$CONFIG"; then
        sed -i "s|^${key}[[:space:]]*=.*|${key} = ${val}|" "$CONFIG" # present but empty
    else
        sed -i "/^\[GENERAL\]/a ${key} = ${val}" "$CONFIG" # insert under [GENERAL]
    fi
    echo "[custom-init] lazylibrarian: set ${key} = ${val}"
}

set_default ebook_dir /media/arr/ebooks
set_default download_dir /media/arr/sabnzbd/complete

# cont-init runs as root; hand the file back to the app user.
chown "${PUID:-1000}:${PGID:-1000}" "$CONFIG" 2>/dev/null || true
