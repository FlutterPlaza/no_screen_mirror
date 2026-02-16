# no_screen_mirror

A Flutter plugin to detect screen mirroring (AirPlay, Miracast), external display connections (HDMI, USB-C, DisplayPort, VGA, DVI), and screen sharing in video calls.

## Demo

![No Screen Mirror Demo](doc/gif/no_screen_mirror.gif)

## Features

- Detect screen mirroring (AirPlay on iOS/macOS, Miracast on Android/Windows)
- Detect external display connections (HDMI, USB-C, DisplayPort, VGA, DVI)
- Detect screen sharing and recording (Zoom, Teams, Slack, Discord, OBS, etc.)
- Report the total number of connected displays
- Real-time streaming of display state changes
- Configurable polling interval for battery-sensitive apps
- Custom screen sharing process names for extensible detection
- Platform capability reporting at runtime
- Cross-platform: Android, iOS, macOS, Linux, Windows, and Web

## Platform Support

| Platform | Mirroring | External Display | Screen Sharing | Detection Method |
|----------|:---------:|:----------------:|:--------------:|------------------|
| Android  | Yes (Miracast) | Yes | Yes (API 34+) | DisplayManager + MediaRouter + ScreenCaptureCallback |
| iOS      | Yes (AirPlay) | Yes | Yes (iOS 11+) | UIScreen notifications + `isCaptured` |
| macOS    | Yes | Yes | Yes | CoreGraphics + CGWindowList + process detection |
| Linux    | No | Yes | Yes | `/sys/class/drm` + `/proc` scanning |
| Windows  | Yes (Miracast) | Yes | Yes | Win32 Display Config + process scanning |
| Web      | No | Chromium 100+ | No | `Screen.isExtended` API |

## Installation

Add `no_screen_mirror` to your `pubspec.yaml`:

```yaml
dependencies:
  no_screen_mirror: ^0.1.2
```

Then run:

```bash
flutter pub get
```

## Permissions

No special permissions are required on any platform. The plugin uses only standard system APIs that are available without additional entitlements or manifest declarations.

## Usage

### Basic Example

```dart
import 'package:no_screen_mirror/no_screen_mirror.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';

final plugin = NoScreenMirror.instance;

// Start listening for display changes
await plugin.startListening();

// Listen to the mirror stream
plugin.mirrorStream.listen((MirrorSnapshot snapshot) {
  print('Screen mirrored: ${snapshot.isScreenMirrored}');
  print('External display: ${snapshot.isExternalDisplayConnected}');
  print('Screen shared: ${snapshot.isScreenShared}');
  print('Display count: ${snapshot.displayCount}');
});

// Stop listening when done
await plugin.stopListening();
```

### Configurable Polling Interval

Control how often the plugin scans for changes on platforms that use polling (Linux, Windows, macOS, Web). iOS and Android are event-driven and ignore this setting.

```dart
await plugin.startListening(
  pollingInterval: const Duration(seconds: 5), // Default: 2 seconds
);
```

### Custom Screen Sharing Process Names

Add your own process names or bundle IDs to the detection list. This extends (does not replace) the built-in list.

```dart
await plugin.startListening(
  customScreenSharingProcesses: [
    'my-conferencing-app', // Linux process name
    'com.example.myapp',   // macOS bundle ID
    'MyApp.exe',           // Windows process name
  ],
);
```

### Platform Capabilities

Check at runtime what the current platform can detect:

```dart
import 'package:no_screen_mirror/mirror_capabilities.dart';

final caps = NoScreenMirror.platformCapabilities;

if (caps.canDetectScreenSharing) {
  // Enable screen sharing UI
}

print(caps.notes); // Platform-specific notes
```

### With StreamSubscription

```dart
import 'dart:async';
import 'package:no_screen_mirror/no_screen_mirror.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';

class _MyWidgetState extends State<MyWidget> {
  final _plugin = NoScreenMirror.instance;
  StreamSubscription<MirrorSnapshot>? _subscription;
  MirrorSnapshot? _snapshot;

  Future<void> _startListening() async {
    await _plugin.startListening();
    _subscription = _plugin.mirrorStream.listen((snapshot) {
      if (!mounted) return;
      setState(() => _snapshot = snapshot);
    });
  }

  Future<void> _stopListening() async {
    await _plugin.stopListening();
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

## API Reference

### NoScreenMirror

| Member | Type | Description |
|--------|------|-------------|
| `instance` | `NoScreenMirror` | Singleton accessor |
| `platformCapabilities` | `MirrorCapabilities` | Runtime platform capability info (static) |
| `mirrorStream` | `Stream<MirrorSnapshot>` | Stream of display state updates |
| `startListening()` | `Future<void>` | Begin monitoring for display changes |
| `stopListening()` | `Future<void>` | Stop monitoring |

### startListening Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pollingInterval` | `Duration` | `Duration(seconds: 2)` | How often to scan on polling-based platforms |
| `customScreenSharingProcesses` | `List<String>` | `[]` | Additional process names to detect as screen sharing |

### MirrorSnapshot

| Property | Type | Description |
|----------|------|-------------|
| `isScreenMirrored` | `bool` | Whether the screen is being mirrored (AirPlay/Miracast) |
| `isExternalDisplayConnected` | `bool` | Whether an external display is connected (HDMI, USB-C, etc.) |
| `isScreenShared` | `bool` | Whether screen sharing or recording is active |
| `displayCount` | `int` | Total number of connected displays |

### MirrorCapabilities

| Property | Type | Description |
|----------|------|-------------|
| `canDetectMirroring` | `bool` | Whether mirroring detection is supported |
| `canDetectExternalDisplay` | `bool` | Whether external display detection is supported |
| `canDetectScreenSharing` | `bool` | Whether screen sharing detection is supported |
| `platform` | `String` | Current platform identifier |
| `notes` | `String` | Platform-specific limitations and notes |

## Platform Notes

### Android

Requires Android 4.2 (API 17) or later. Uses `DisplayManager` for external display detection and `MediaRouter` for Miracast/wireless mirroring detection. Screen sharing detection uses `Activity.ScreenCaptureCallback` which requires Android 14+ (API 34) — on older versions, `isScreenShared` is always `false`.

### iOS

Uses `UIScreen` notifications for display connection events and `isCaptured` (iOS 11+) for AirPlay mirroring and screen sharing detection. The `isCaptured` property covers screen recording, AirPlay mirroring, and screen sharing by third-party apps.

### macOS

Uses CoreGraphics APIs (`CGGetOnlineDisplayList`, `CGDisplayMirrorsDisplay`) to detect external displays and mirroring (including Luna Display). Screen sharing is detected via the Control Center `AudioVideoModule` indicator (catches all screen capture including browser-based sharing like Google Meet), `CGSessionCopyCurrentDictionary` for system-level screen sharing, and running application bundle ID checks. Custom bundle IDs can be added via `customScreenSharingProcesses`.

### Linux

Scans `/sys/class/drm/` for display connectors. Supports eDP, LVDS, DSI (built-in) and HDMI, DP, VGA, DVI (external). Screen mirroring detection is **not available** (always returns `false`) — there is no kernel-level mirroring API. Screen sharing is detected by scanning `/proc/*/comm` for known process names (zoom, teams, slack, discord, obs, ffmpeg, etc.).

### Windows

Uses Win32 Display Configuration APIs for external display and Miracast detection via `QueryDisplayConfig`. Screen sharing is detected by scanning running processes via `CreateToolhelp32Snapshot` for known executables (Zoom.exe, Teams.exe, slack.exe, Discord.exe, obs64.exe, ffmpeg.exe, etc.).

### Web

Uses the `Screen.isExtended` API available in Chromium 100+. Safari and Firefox are not supported (values default to `false`). Screen mirroring and screen sharing detection are **not available** in browsers. The plugin also listens for `visibilitychange` events to re-scan when the tab is shown/hidden.

## Built-in Screen Sharing Process Lists

### macOS (Bundle IDs)
`us.zoom.xos`, `com.microsoft.teams`, `com.microsoft.teams2`, `com.tinyspeck.slackmacgap`, `com.hnc.Discord`, `com.obsproject.obs-studio`, `com.apple.QuickTimePlayerX`, `com.loom.desktop`, `com.apple.FaceTime`, `com.apple.ScreenSharing`, `com.cisco.webexmeetingsapp`, `com.webex.meetingmanager`, `com.gotomeeting`, `com.logmein.GoToMeeting`, `com.ringcentral.RingCentral`, `com.bluejeans.BlueJeans`, `com.whereby.app`, `com.pop.pop.app`, `com.crowdcast.Crowdcast`, `com.around.Around`, `com.livestorm.app`

### Linux (Process Names)
`zoom`, `teams`, `teams-for-linux`, `slack`, `discord`, `obs`, `ffmpeg`, `simplescreenrecorder`, `kazam`, `peek`, `recordmydesktop`, `vokoscreen`

### Windows (Executable Names)
`Zoom.exe`, `CptHost.exe`, `Teams.exe`, `ms-teams.exe`, `slack.exe`, `Discord.exe`, `obs64.exe`, `obs32.exe`, `ffmpeg.exe`
