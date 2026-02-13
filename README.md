# no_screen_mirror

A Flutter plugin to detect screen mirroring (AirPlay, Miracast) and external display connections (HDMI, USB-C, DisplayPort, VGA, DVI).

## Features

- Detect screen mirroring (AirPlay on iOS/macOS, Miracast on Android/Windows)
- Detect external display connections (HDMI, USB-C, DisplayPort, VGA, DVI)
- Report the total number of connected displays
- Real-time streaming of display state changes
- Cross-platform: Android, iOS, macOS, Linux, Windows, and Web

## Platform Support

| Platform | Mirroring Detection | External Display Detection | Detection Method |
|----------|:-------------------:|:--------------------------:|------------------|
| Android  | Yes (Miracast)      | Yes                        | DisplayManager + MediaRouter |
| iOS      | Yes (AirPlay)       | Yes                        | UIScreen notifications |
| macOS    | Yes                 | Yes                        | CoreGraphics APIs |
| Linux    | No                  | Yes                        | `/sys/class/drm` scanning |
| Windows  | Yes (Miracast)      | Yes                        | Win32 Display Config APIs |
| Web      | No                  | Chromium 100+ only         | `Screen.isExtended` API |

## Installation

Add `no_screen_mirror` to your `pubspec.yaml`:

```yaml
dependencies:
  no_screen_mirror: ^0.1.0
```

Then run:

```bash
flutter pub get
```

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
  print('Display count: ${snapshot.displayCount}');
});

// Stop listening when done
await plugin.stopListening();
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
| `mirrorStream` | `Stream<MirrorSnapshot>` | Stream of display state updates |
| `startListening()` | `Future<void>` | Begin monitoring for display changes |
| `stopListening()` | `Future<void>` | Stop monitoring |

### MirrorSnapshot

| Property | Type | Description |
|----------|------|-------------|
| `isScreenMirrored` | `bool` | Whether the screen is being mirrored (AirPlay/Miracast) |
| `isExternalDisplayConnected` | `bool` | Whether an external display is connected (HDMI, USB-C, etc.) |
| `displayCount` | `int` | Total number of connected displays |

## Platform Notes

### Android
Requires Android 4.2 (API 17) or later. Uses `DisplayManager` for external display detection and `MediaRouter` for Miracast/wireless mirroring detection.

### iOS
Uses `UIScreen` notifications for display connection events and `isCaptured` (iOS 11+) for AirPlay mirroring detection.

### macOS
Uses CoreGraphics APIs (`CGDisplayIsBuiltin`, `CGDisplayMirrorsDisplay`) to distinguish external displays and detect mirroring.

### Linux
Scans `/sys/class/drm/` for display connectors. Supports eDP, LVDS, DSI (built-in) and HDMI, DP, VGA, DVI (external). Screen mirroring detection is not available (always returns `false`).

### Windows
Uses Win32 Display Configuration APIs for external display and Miracast detection.

### Web
Uses the `Screen.isExtended` API available in Chromium 100+. Safari and Firefox are not supported (values default to `false`).