Keychain fix for saved-server credentials.

## Fixed

- **Keychain rejecting saved-server passwords after an update** — when a saved server's password was stored by a previous build with a different code signature, macOS would refuse to release it to the new binary and surface a misleading "the password you entered is not correct" alert during login. Editing the server to re-enter the password failed the same way before it could rewrite the stale entry, leaving the server unreachable. The app now shows a clear error pointing at Keychain Access, keeps the editor reachable, and falls back to overwriting the stale entry via `SecItemUpdate` when the delete step is denied — so re-saving from inside the app fixes it in most cases. Thanks to [@vlad-a-c](https://github.com/vlad-a-c) for the report (#12).

## Install

If you're on 1.3.0, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.1-23.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
