#!/bin/sh

# Exit immediately if the DIUN_ENTRY_IMAGE environment variable is not set.
if [ -z "$DIUN_ENTRY_IMAGE" ]; then
    echo "DIUN_ENTRY_IMAGE is not set. Exiting."
    exit 1
fi

# Skip digest-only references like docker.io/library/redis@sha256:...
# Without a tag we can't disambiguate which container uses this image
# (e.g. redis is used by paperless, dawarich, and infisical with different
# tags). DIUN re-reports updates with proper tags on subsequent runs.
BEFORE_AT="${DIUN_ENTRY_IMAGE%@*}"
LAST_PART="${BEFORE_AT##*/}"
case "$LAST_PART" in
    *:*) ;;
    *)
        echo "Skipping digest-only image reference (no tag): $DIUN_ENTRY_IMAGE"
        exit 0
        ;;
esac

OUTPUT_FILE="/script/pendingContainerUpdates.txt"

# Check if pendingContainerUpdates.txt exists, create it if it doesn't
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Creating pendingContainerUpdates.txt file..."
    touch "$OUTPUT_FILE"
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Failed to create pendingContainerUpdates.txt file."
    exit 1
fi

# Additive, purely informational sidecar file: one JSON line per (stack,
# image) pair, so the web admin can show *which* image triggered a stack's
# pending-update flag. Never read by update-containers-from-diun-list.sh --
# OUTPUT_FILE's plain stack-name-per-line format is a hard contract with
# all-containers.sh --container-list and must not change.
DETAILS_FILE="/script/pendingContainerUpdateDetails.jsonl"
if [ ! -f "$DETAILS_FILE" ]; then
    touch "$DETAILS_FILE"
fi

IMAGE_NAME=$(echo "$DIUN_ENTRY_IMAGE" | sed 's/:/_/g' | cut -d '/' -f 3)

# If the image name contains an @, we need to remove it and everything after it.
IMAGE_NAME=$(echo "$IMAGE_NAME" | sed 's/@.*//g')

# Remove _latest from the image name IF it exists
IMAGE_NAME=$(echo "$IMAGE_NAME" | sed 's/_latest//g')

OUTPUT_IMAGE_NAME="$IMAGE_NAME"

# Swap out generic image names for the container folder that uses them.
case "$IMAGE_NAME" in
    sockpuppetbrowser|changedetection.io)
        OUTPUT_IMAGE_NAME="changedetection"
        ;;
    postgis_17-3.5-alpine|redis_7.4-alpine|postgis_18-3.6-alpine)
        OUTPUT_IMAGE_NAME="dawarich"
        ;;
    redis_7|postgres_16|tika|paperless-ngx|postgres_18)
        OUTPUT_IMAGE_NAME="paperless"
        ;;
    couchdb)
        OUTPUT_IMAGE_NAME="obsidian-babel-livesync"
        ;;
    # netdata/netdata's bare/"latest" tag is actually their nightly channel
    # (see the version-drift upgrade plan, 2026-08-29) -- this host pins
    # :stable instead, which changes the parsed IMAGE_NAME from the
    # coincidentally-already-correct "netdata" to "netdata_stable".
    netdata_stable)
        OUTPUT_IMAGE_NAME="netdata"
        ;;
    portainer-ce)
        OUTPUT_IMAGE_NAME="portainer"
        ;;
    mongo_6|your_spotify|mongo_8)
        OUTPUT_IMAGE_NAME="your-spotify"
        ;;
    mariadb_10|mariadb_12)
        OUTPUT_IMAGE_NAME="mariadb nextcloud" # Multiple names, space-separated
        ;;
    actual-server)
        OUTPUT_IMAGE_NAME="actual-budget quicken actual-budget-api" # Multiple names, space-separated
        ;;
    pgvector_pg17|hub)
        OUTPUT_IMAGE_NAME="formbricks"
        ;;
    valkey_8-alpine)
        OUTPUT_IMAGE_NAME="searxng"
        ;;
    # This host (not the shared module default) moved infisical/paperless/
    # dawarich/searxng's redis-family sidecars all onto the SAME valkey:9-alpine
    # tag via each folder's own compose.override.yaml (see the 2026-08-29
    # version-drift upgrade plan) -- unlike the old per-stack-unique redis tags
    # above, one tag now covers four stacks at once, so it maps to all of them.
    valkey_9-alpine)
        OUTPUT_IMAGE_NAME="infisical paperless dawarich searxng"
        ;;
    immich-machine-learning_*|immich-server_*|postgres_14-vectorchord0.4.3-pgvectors0.2.0|valkey_9)
        OUTPUT_IMAGE_NAME="immich"
        ;;
    factorio_*)
        OUTPUT_IMAGE_NAME="factorio"
        ;;
    forgejo_*)
        OUTPUT_IMAGE_NAME="forgejo"
        ;;
    beszel-agent)
        OUTPUT_IMAGE_NAME="beszel"
        ;;
    # itzg/minecraft-server + itzg/mc-backup both live in the minecraft-java stack.
    # (The bedrock "minecraft" folder builds from a git clone, so it has no watched
    # image and never shows up here.)
    minecraft-server*|mc-backup*)
        OUTPUT_IMAGE_NAME="minecraft-java"
        ;;
    speedtest-tracker)
        OUTPUT_IMAGE_NAME="speedtest"
        ;;
    thelounge)
        OUTPUT_IMAGE_NAME="the-lounge"
        ;;
    karakeep_*)
        OUTPUT_IMAGE_NAME="karakeep"
        ;;
    rabbitmq_3|postgres_15|documentserver)
        OUTPUT_IMAGE_NAME="eurooffice"
        ;;
    # Unique app images: match on name and IGNORE the tag (glob), so a version
    # bump (nextcloud 33->34, a new forgejo/infisical release, an ES point
    # release) keeps mapping to the right folder instead of falling through and
    # writing a junk "name_tag" entry. Do NOT do this for shared base images
    # (redis/postgres/valkey) below -- there the tag is what disambiguates which
    # stack owns them.
    elasticsearch_*|nextcloud_*)
        OUTPUT_IMAGE_NAME="nextcloud"
        ;;
    postgres_14-alpine|redis_7-alpine|infisical_*|postgres_18-alpine)
        OUTPUT_IMAGE_NAME="infisical"
        ;;
    obsidian_*)
        OUTPUT_IMAGE_NAME="obsidian"
        ;;
    gluetun)
        OUTPUT_IMAGE_NAME="recon secure-browser"
        ;;
    ungoogled-chromium)
        OUTPUT_IMAGE_NAME="secure-browser"
        ;;
    whiteboard)
        OUTPUT_IMAGE_NAME="nextcloud-whiteboard"
        ;;
    uptime-kuma)
        OUTPUT_IMAGE_NAME="uptime"
        ;;
    tsidp_*)
        OUTPUT_IMAGE_NAME="tsidp"
        ;;
    tinyfilemanager_*)
        OUTPUT_IMAGE_NAME="archive"
        ;;
    stirling-pdf_*)
        OUTPUT_IMAGE_NAME="stirling-pdf"
        ;;
    code-server)
        OUTPUT_IMAGE_NAME="code"
        ;;
    tclip)
        OUTPUT_IMAGE_NAME="paste"
        ;;
    ac)
        OUTPUT_IMAGE_NAME="archive"
        ;;
    prowlarr|sonarr|radarr|lidarr|mylar3|lazylibrarian|qbittorrent|sabnzbd|bazarr|decluttarr|flaresolverr)
        OUTPUT_IMAGE_NAME="recon"
        ;;
    actual-http-api)
        OUTPUT_IMAGE_NAME="actual-budget-api"
        ;;
    valkey)
        OUTPUT_IMAGE_NAME="formbricks"
        ;;
    pastefy)
        OUTPUT_IMAGE_NAME="paste"
        ;;
    connect-api|connect-sync)
        OUTPUT_IMAGE_NAME="1password"
        ;;
    gotenberg)
        OUTPUT_IMAGE_NAME="paperless"
        ;;
    tailscale)
        # We can skip tailscale for now.
        exit 0
        ;;
esac

# Loop over space-separated names
for name in $OUTPUT_IMAGE_NAME; do
    if grep -q "$name" "$OUTPUT_FILE"; then
        echo "Image $name is already in the update list file."
    else
        echo "Adding image $name to the update list file."
        echo "$name" >> "$OUTPUT_FILE"
    fi

    DETAIL_LINE="{\"stack\":\"$name\",\"image\":\"$LAST_PART\"}"
    if ! grep -qF "$DETAIL_LINE" "$DETAILS_FILE"; then
        echo "$DETAIL_LINE" >> "$DETAILS_FILE"
    fi
done

# Fix permissions on the files
chown 1000:1000 "$OUTPUT_FILE" "$DETAILS_FILE"
