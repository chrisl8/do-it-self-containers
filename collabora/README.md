# Collabora Online (CODE)

Collabora Online document editor, embedded in Nextcloud via the Nextcloud Office
(richdocuments) app. TLS is terminated by the Tailscale sidecar; Collabora runs
plain HTTP internally. See `compose.yaml` for the WOPI/aliasgroup wiring.

## Known limitation: spreadsheet horizontal swipe gets stuck on the Nextcloud iOS app

**Symptom.** In the **Nextcloud iOS app**, editing a spreadsheet (Calc) and
swiping horizontally — e.g. swiping right to get back to column A — very often
"pulls" the whole document and leaves you on a **blue screen with a spinning
loading icon that never resolves**. The only recovery is the left chevron at the
top to fully close the file, then reopen it.

**Cause — not a server/container problem.** This is a known, currently-open bug
in the **Nextcloud iOS app's gesture handling**, not in Collabora or this
container's configuration. The iOS app has a native left→right edge swipe that
means "close document / go back." A horizontal scroll inside Calc collides with
that gesture, which fires partway, tears down / re-requests the WOPI editing
session, and strands you on Collabora's loading splash. There is **no Collabora
image version or `extra_params` flag that fixes this** — the offending gesture
lives in the iOS app, and the requested upstream fix (disable/toggle the
swipe-close gesture while a document is open) has not landed.

References:

- CollaboraOnline/online #11153 — "scrolling sheet in collabora Calc in Nextcloud
  iOS app is unusable" (open; bug + regression; touch-input specific)
  <https://github.com/CollaboraOnline/online/issues/11153>
- Nextcloud forum — "Gestures make calc integration on iOS app unusable"
  <https://help.nextcloud.com/t/gestures-make-calc-integration-on-ios-app-unusable/243551>
- Nextcloud forum — "Scrolling issue in Spreadsheets on mobile"
  <https://help.nextcloud.com/t/nextcloud-office-scrolling-issue-in-spreadsheets-on-mobile/188535>

**Workarounds** (roughly most → least effective):

1. **Install Nextcloud as a standalone home-screen PWA and edit there — not in
   the native Nextcloud app.** In mobile Safari open `nextcloud.<TS_DOMAIN>` →
   Share → **Add to Home Screen**. Launched from that icon, Nextcloud runs in
   standalone mode with **no Safari chrome (no edge-swipe-back) and is not the
   native app (no swipe-to-close)** — so the gesture that strands you on the blue
   loading screen no longer exists, rather than merely being routed around. This
   is the single highest-leverage fix and costs nothing; the offending gesture
   fires at the OS/app layer *before* Collabora sees the touch, so it cannot be
   disabled from the server — removing the gesture (via the PWA) is the only
   server-independent fix. Test this first.
2. **Use a tablet (e.g. iPad) for heavy spreadsheet work.** Collabora's tablet UI
   is a substantially better experience than its phone UI (full toolbar, far less
   pinch-and-jab) and is independent of this gesture bug. Biggest quality jump
   available short of a desktop.
3. **Pinch-zoom out, then tap** the target cell (e.g. column A) rather than
   swiping to it; zoom back in afterward. A finger jab never triggers the edge
   gesture.
4. **Start the scroll from the interior of the sheet**, not near the left screen
   edge, and keep the drag short — the close gesture is most easily triggered by
   edge-to-edge horizontal drags.
5. **Do heavy spreadsheet editing on a desktop.** Mobile Calc in Collabora is
   rough regardless of this bug.

Note: Collabora is effectively the only viable self-hosted option for editing
real spreadsheets on mobile. OnlyOffice's in-Nextcloud web editor disallows
mobile editing, and its native app has been observed to silently fail to save
(data loss) — so it is not a safe alternative for this workflow.

Track CollaboraOnline/online #11153 for the eventual app-side fix.
