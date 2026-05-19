Bug fix release: fixes a crash that could occur when quitting the app while connected to a server.

## Fixed

- **Quit crash**: a race condition in the TeamTalk SDK could crash the app on quit when an active session was being torn down. The app now waits briefly for the SDK's internal threads to finish before letting the process exit.

## Install

1. Download `ttaccessible-1.0.1-14.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
