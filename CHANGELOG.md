## 0.1.1

* **Screen sharing detection** across all platforms via `isScreenShared` on `MirrorSnapshot`.
  * iOS 11+: `UIScreen.main.isCaptured` (covers AirPlay, screen recording, screen sharing).
  * Android 14+ (API 34): `Activity.ScreenCaptureCallback`.
  * macOS: Process detection for Zoom, Teams, Slack, Discord, OBS, QuickTime, Loom.
  * Linux: `/proc` process scanning for known screen sharing/recording apps.
  * Windows: `CreateToolhelp32Snapshot` process scanning.
  * Web: `isScreenShared` always `false` (no browser API).
* **Configurable polling interval** via `startListening(pollingInterval: Duration(...))`.
  * Default: 2 seconds. Applies to Linux, Windows, macOS, and Web.
  * iOS and Android are event-driven and do not poll.
* **Custom screen sharing process names** via `startListening(customScreenSharingProcesses: [...])`.
  * Add your own process/bundle ID names on macOS, Linux, and Windows.
  * Extends the built-in list, does not replace it.
* **Platform capability reporting** via `NoScreenMirror.platformCapabilities`.
  * Returns `MirrorCapabilities` with `canDetectMirroring`, `canDetectExternalDisplay`, `canDetectScreenSharing`, and `notes`.
  * Works offline — no native call needed.
* **macOS periodic screen sharing check** — screen sharing is now detected via a periodic timer instead of only on display change events.
* **Web visibility change listener** — emits a scan on `visibilitychange` events in addition to polling.
* **Improved example app** with warning banners on mirroring/sharing detection and a platform capabilities card.
* **Fixed integration test** — replaced placeholder `getPlatformVersion` test with actual plugin API tests.
* **SDK constraint** bumped to `>=3.4.0 <4.0.0`.

## 0.0.1

* Initial release.
* Detect screen mirroring (AirPlay on iOS/macOS, Miracast on Android/Windows).
* Detect external display connections (HDMI, USB-C, DisplayPort, VGA, DVI).
* Report total connected display count via `MirrorSnapshot`.
* Real-time streaming of display state changes via `mirrorStream`.
* Platform support: Android, iOS, macOS, Linux, Windows, and Web.
* Android implementation using `DisplayManager` and `MediaRouter` APIs.
* iOS implementation using `UIScreen` notifications and `isCaptured`.
* macOS implementation using CoreGraphics APIs.
* Linux implementation scanning `/sys/class/drm/` connectors.
* Windows implementation using Win32 Display Configuration APIs.
* Web implementation using `Screen.isExtended` API (Chromium 100+).
* Example app demonstrating plugin usage.
* Unit tests for platform interface, method channel, and web implementation.
