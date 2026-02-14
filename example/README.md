# no_screen_mirror example

Demonstrates how to use the `no_screen_mirror` plugin to detect screen mirroring, external displays, and screen sharing.

## Running the example

```bash
cd example
flutter run
```

## What the example shows

- **Live status stream** — Listens for `MirrorSnapshot` updates and displays the current mirroring/sharing state.
- **Warning banners** — Shows a `MaterialBanner` when screen mirroring or screen sharing is detected.
- **Platform capabilities** — Displays what the current platform can detect (mirroring, external displays, screen sharing).
- **Configurable polling** — Starts listening with a custom polling interval and optional custom process names.

## Testing

Connect an external display, start AirPlay/Miracast mirroring, or launch a screen-sharing app (Zoom, Teams, etc.) to see the status update in real time.
