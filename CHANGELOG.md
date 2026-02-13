## 0.1.0

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
