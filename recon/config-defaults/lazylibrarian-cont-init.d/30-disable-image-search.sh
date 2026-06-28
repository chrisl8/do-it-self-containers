#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Disable LazyLibrarian's web image-search fallback for covers and author photos.
#
# When LazyLibrarian can't find a real cover/author image from a proper source
# (GoodReads, OpenLibrary, Google Books ISBN, Hardcover, LibraryThing), it falls
# back to running a Baidu/Bing/Google *image search* via the bundled `icrawler`
# library and blindly caches the first result. In practice that returns ads,
# watermarked stock art, AI-generated junk, and random people -- not book covers
# or author portraits. There is NO config.ini / web-UI toggle for this in the
# DobyTang fork; it is gated only on Pillow being importable, which it always is
# in this image (calibre mod). So we neuter it at the source.
#
# We disable the two crawl entry points in images.py by short-circuiting their
# guard conditions to False:
#   get_book_cover():   `if PIL and safeparams:`  -> never runs Baidu/Bing/Google
#   get_author_image(): `if PIL and author:`      -> never runs Google/Bing
# Every legitimate cover source runs *before* these blocks, so real covers are
# unaffected; only the junk fallback is removed. Authors/books with no real
# image just show the nophoto/nocover placeholder.
#
# The sed is idempotent: once a line reads `if False and PIL ...` the match no
# longer fires. This script must never abort container startup, so it avoids
# `set -e` and always exits 0.

TARGET=/app/lazylibrarian/lazylibrarian/images.py

# Only act inside the LazyLibrarian container.
[[ -f "$TARGET" ]] || exit 0

patch_guard() {
    # $1 = the exact guard expression to disable, e.g. "PIL and safeparams:"
    local guard="$1"
    if grep -qE "^[[:space:]]*if ${guard}\$" "$TARGET"; then
        sed -i -E "s/^([[:space:]]*)if ${guard}\$/\1if False and ${guard}  # LL-img-search-disabled/" "$TARGET"
        echo "[30-disable-image-search] disabled crawl guard: if ${guard}"
    elif grep -qE "if False and ${guard}" "$TARGET"; then
        : # already patched, nothing to do
    else
        # Guard text changed in a LazyLibrarian update -- warn, but do not fail.
        echo "[30-disable-image-search] WARNING: guard 'if ${guard}' not found; image-search may be re-enabled after an update"
    fi
}

patch_guard "PIL and safeparams:"
patch_guard "PIL and author:"

exit 0
