In-channel media streaming with video, and a push-to-talk fix.

## Added

- **In-channel media streaming with video** — stream audio or video files directly into a channel from the connected-server view. Embedded playback controls (play, pause, seek, broadcast gain) and a collapsible video panel keep the main UI fully usable. Format support depends on what TeamTalk can open on your Mac; 10-bit video is rejected before streaming. Optional system `ffmpeg` (e.g. `brew install ffmpeg`) lets the app probe files the SDK can't open natively. Thanks to [@xogium](https://github.com/xogium) for the feature.

## Fixed

- **Push-to-talk silent mic** — selecting Push-to-talk mode without configuring a hotkey would mute the microphone forever. The app now falls back to always-on transmission when no shortcut is set and shows a warning in Preferences > Audio.

## Install

If you're on 1.2.0, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.0-22.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
