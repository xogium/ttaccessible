UX and accessibility polish: a contextual toolbar, simpler announcement settings, and quicker access to the project on GitHub.

## Added

- **Window toolbar with context-aware buttons** — the main window now has a toolbar. On the saved-servers list: connect, new, edit, preferences. Once connected: microphone, master mute, recording, hear yourself, disconnect, preferences. Stateful items (mute, recording) reflect the live state, and the toolbar swaps itself whenever the connection state changes via the toolbar, the menu, or a keyboard shortcut. Thanks to [@Quinton1110](https://github.com/QuintonW) for the discoverability suggestion.
- **Global background announcement mode** — Preferences > Announcements now has a "Use the same mode for all event types" toggle. Flip it on and a single dropdown applies to private messages, channel messages, broadcasts, and history at once. Per-event customization still available when needed. Existing configurations with the same mode everywhere are migrated automatically. Thanks to [@Quinton1110](https://github.com/QuintonW).
- **Help menu** — added "View Project on GitHub" and "Report an Issue…" entries. The issue link lands on a template picker (bug report or feature request) with structured fields so reports include the version, reproduction steps, and audio log path right away.
- **Better default nickname** — uses your macOS full name's first word instead of the device name, so French/Romance locale Macs no longer ship with names like "de" or "Mac". Live-syncs the nickname field while you type if it still matches the default. Thanks to [@Quinton1110](https://github.com/QuintonW) (#9).

## Fixed

- **Empty video panel no longer takes up space** — the collapsible video panel is now hidden when no media stream is active.

## Install

If you're on 1.3.0 or 1.3.1, ttaccessible will install this update for you — no action needed.

Manual install:

1. Download `ttaccessible-1.3.2-24.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.
