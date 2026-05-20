Critical Sparkle fix. **Manual install required this one time** if you're on 1.1.0 or 1.1.1.

## Fixed

- **Sparkle update install failed with "An error occurred while running the updater."** The mach-lookup entitlements that let the sandboxed app reach Sparkle's helper XPC services were signed with the literal string `$(PRODUCT_BUNDLE_IDENTIFIER)-spks` instead of `com.math65.ttaccessible-spks` because the build script's call to `codesign` doesn't expand Xcode build variables. Hardcoded the bundle identifier in the entitlements so the substitution happens at-source.

## One-time manual install

If you're on **1.1.0 or 1.1.1**, Sparkle in those versions cannot install this update for you — that's the bug we're fixing. Install once manually:

1. Download `ttaccessible-1.1.2-19.zip` below.
2. Unzip and drag `ttaccessible.app` into your `/Applications` folder, replacing the previous version.
3. Double-click — no Gatekeeper warning thanks to notarization.

From 1.1.2 onward, Sparkle takes over normally for every future release.

If you're on 1.0.2, the old in-app updater will surface 1.1.2 the next time you check — install it manually the same way (as planned for the Sparkle migration).
