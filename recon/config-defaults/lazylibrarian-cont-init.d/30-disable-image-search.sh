#!/usr/bin/with-contenv bash
# shellcheck shell=bash
# Stop LazyLibrarian from caching junk (non-cover) images for books & authors.
#
# Two distinct upstream bugs produce bogus "covers"/author photos:
#
# 1. WEB IMAGE-SEARCH FALLBACK. When LazyLibrarian can't find a real image from
#    a proper source (GoodReads, OpenLibrary, Google Books ISBN, Hardcover,
#    LibraryThing), it runs a Baidu/Bing/Google *image search* via the bundled
#    `icrawler` library and blindly caches the first hit -- ads, watermarked
#    stock art, AI-generated junk, random people, lecture slides. There is NO
#    config.ini / web-UI toggle in the DobyTang fork; it is gated only on Pillow
#    being importable, which it always is here (calibre mod). We disable the two
#    crawl entry points in images.py by short-circuiting their guards to False:
#      get_book_cover():   `if PIL and safeparams:`  -> never runs the crawlers
#      get_author_image(): `if PIL and author:`      -> never runs the crawlers
#    Every legitimate source runs *before* these blocks, so real covers are
#    unaffected; items with no real image just show the nophoto/nocover image.
#
# 2. GOODREADS GENERIC-LOGO og:image. The GoodReads cover scrape falls back to
#    the page's og:image when there is no <img id="coverImage">. For a book with
#    no cover that og:image is GoodReads' generic social-share logo
#    (https://s.gr-assets.com/assets/facebook/goodreads_wide-*.png), cached as
#    the "cover". The existing URL filter only rejects 'nocover'/'nophoto', so we
#    extend it to also reject the 'assets/facebook' generic-logo path (harmless
#    for the OpenLibrary filter that shares the same line shape).
#
# All edits are idempotent and this script must never abort container startup,
# so it avoids `set -e` and always exits 0.

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

# Reject the GoodReads generic-logo og:image. Append the extra condition to any
# cover-URL filter line that doesn't already have it.
if grep -qE "'nophoto' not in img:" "$TARGET"; then
    if grep -qE "'nophoto' not in img and 'assets/facebook' not in img:" "$TARGET"; then
        : # already patched
    else
        sed -i -E "s/'nophoto' not in img:/'nophoto' not in img and 'assets\/facebook' not in img:/g" "$TARGET"
        echo "[30-disable-image-search] added GoodReads generic-logo (assets/facebook) cover filter"
    fi
else
    echo "[30-disable-image-search] WARNING: cover-URL filter line not found; GoodReads logo filter not applied"
fi

exit 0
