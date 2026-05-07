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
    postgis_17-3.5-alpine|redis_7.4-alpine)
        OUTPUT_IMAGE_NAME="dawarich"
        ;;
    redis_7|postgres_16|tika|paperless-ngx)
        OUTPUT_IMAGE_NAME="paperless"
        ;;
    couchdb)
        OUTPUT_IMAGE_NAME="obsidian-babel-livesync"
        ;;
    portainer-ce)
        OUTPUT_IMAGE_NAME="portainer"
        ;;
    mongo_6|your_spotify)
        OUTPUT_IMAGE_NAME="your-spotify"
        ;;
    mariadb_10)
        OUTPUT_IMAGE_NAME="mariadb nextcloud" # Multiple names, space-separated
        ;;
    actual-server)
        OUTPUT_IMAGE_NAME="actual-budget quicken actual-budget-api" # Multiple names, space-separated
        ;;
    code)
        OUTPUT_IMAGE_NAME="collabora"
        ;;
    pgvector_pg17)
        OUTPUT_IMAGE_NAME="formbricks"
        ;;
    valkey_8-alpine)
        OUTPUT_IMAGE_NAME="searxng"
        ;;
    immich-machine-learning_release|immich-server_release|postgres_14-vectorchord0.4.3-pgvectors0.2.0|valkey_9)
        OUTPUT_IMAGE_NAME="immich"
        ;;
    factorio_stable)
        OUTPUT_IMAGE_NAME="factorio"
        ;;
    forgejo_12)
        OUTPUT_IMAGE_NAME="forgejo"
        ;;
    beszel-agent)
        OUTPUT_IMAGE_NAME="beszel"
        ;;
    speedtest-tracker)
        OUTPUT_IMAGE_NAME="speedtest"
        ;;
    thelounge)
        OUTPUT_IMAGE_NAME="the-lounge"
        ;;
    karakeep_release)
        OUTPUT_IMAGE_NAME="karakeep"
        ;;
    rabbitmq_3|postgres_15|documentserver)
        OUTPUT_IMAGE_NAME="onlyoffice"
        ;;
    elasticsearch_9.1.0)
        OUTPUT_IMAGE_NAME="nextcloud"
        ;;
    postgres_14-alpine|redis_7-alpine)
        OUTPUT_IMAGE_NAME="infisical"
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
    tsidp_unstable)
        OUTPUT_IMAGE_NAME="tsidp"
        ;;
    tinyfilemanager_master)
        OUTPUT_IMAGE_NAME="filez"
        ;;
    stirling-pdf_V2-Beta)
        OUTPUT_IMAGE_NAME="stirling-pdf"
        ;;
    code-server)
        OUTPUT_IMAGE_NAME="code"
        ;;
    tclip)
        OUTPUT_IMAGE_NAME="paste"
        ;;
    ac)
        OUTPUT_IMAGE_NAME="filez"
        ;;
    prowlarr|sonarr|radarr|lidarr|mylar3|lazylibrarian|qbittorrent|sabnzbd|bazarr)
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
done

# Fix permissions on the file
chown 1000:1000 "$OUTPUT_FILE"
