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

1. **Edit spreadsheets in mobile Safari instead of the Nextcloud iOS app.** Open
   `nextcloud.<TS_DOMAIN>` in Safari and open the sheet there; this sidesteps the
   app's swipe-to-close gesture entirely. Add a home-screen shortcut for
   convenience.
2. **Pinch-zoom out, then tap** the target cell (e.g. column A) rather than
   swiping to it; zoom back in afterward. A finger jab never triggers the edge
   gesture.
3. **Start the scroll from the interior of the sheet**, not near the left screen
   edge, and keep the drag short — the close gesture is most easily triggered by
   edge-to-edge horizontal drags.
4. **Do heavy spreadsheet editing on a desktop.** Mobile Calc in Collabora is
   rough regardless of this bug.

Track CollaboraOnline/online #11153 for the eventual app-side fix.
