import 'src/platform_info_stub.dart'
    if (dart.library.io) 'src/platform_info_io.dart'
    if (dart.library.js_interop) 'src/platform_info_web.dart';

/// Describes what screen-related detection features the current platform supports.
///
/// Use [MirrorCapabilities.current] to obtain the capabilities for the
/// platform the app is running on.
class MirrorCapabilities {
  /// Whether this platform can detect screen mirroring (e.g. AirPlay, Miracast).
  final bool canDetectMirroring;

  /// Whether this platform can detect external display connections (e.g. HDMI).
  final bool canDetectExternalDisplay;

  /// Whether this platform can detect active screen sharing sessions.
  final bool canDetectScreenSharing;

  /// The name of the current platform (e.g. `'android'`, `'ios'`, `'web'`).
  final String platform;

  /// Human-readable notes about platform-specific behavior or limitations.
  final String notes;

  /// Creates a [MirrorCapabilities] with the given values.
  const MirrorCapabilities({
    required this.canDetectMirroring,
    required this.canDetectExternalDisplay,
    required this.canDetectScreenSharing,
    required this.platform,
    required this.notes,
  });

  static final Map<String, MirrorCapabilities> _capabilities = {
    'android': const MirrorCapabilities(
      canDetectMirroring: true,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: true,
      platform: 'android',
      notes: 'Screen sharing detection requires Android 14+ (API 34). '
          'Mirroring uses DisplayManager + MediaRouter.',
    ),
    'ios': const MirrorCapabilities(
      canDetectMirroring: true,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: true,
      platform: 'ios',
      notes: 'Screen sharing detection uses UIScreen.isCaptured (iOS 11+). '
          'Covers AirPlay, screen recording, and screen sharing.',
    ),
    'macos': const MirrorCapabilities(
      canDetectMirroring: true,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: true,
      platform: 'macos',
      notes: 'Screen sharing detected via running process inspection. '
          'Uses CoreGraphics for display and mirroring detection.',
    ),
    'linux': const MirrorCapabilities(
      canDetectMirroring: false,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: true,
      platform: 'linux',
      notes: 'Mirroring detection is not available (no kernel API). '
          'Screen sharing detected via /proc process scanning.',
    ),
    'windows': const MirrorCapabilities(
      canDetectMirroring: true,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: true,
      platform: 'windows',
      notes: 'Miracast detection via QueryDisplayConfig. '
          'Screen sharing detected via process scanning.',
    ),
    'web': const MirrorCapabilities(
      canDetectMirroring: false,
      canDetectExternalDisplay: true,
      canDetectScreenSharing: false,
      platform: 'web',
      notes: 'External display detection requires Chromium 100+. '
          'Safari and Firefox are not supported.',
    ),
  };

  /// Returns the [MirrorCapabilities] for the current platform.
  static MirrorCapabilities get current {
    final name = getPlatformName();
    return _capabilities[name] ??
        const MirrorCapabilities(
          canDetectMirroring: false,
          canDetectExternalDisplay: false,
          canDetectScreenSharing: false,
          platform: 'unknown',
          notes: 'Unsupported platform.',
        );
  }

  @override
  String toString() {
    return 'MirrorCapabilities('
        'platform: $platform, '
        'canDetectMirroring: $canDetectMirroring, '
        'canDetectExternalDisplay: $canDetectExternalDisplay, '
        'canDetectScreenSharing: $canDetectScreenSharing'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MirrorCapabilities &&
        other.canDetectMirroring == canDetectMirroring &&
        other.canDetectExternalDisplay == canDetectExternalDisplay &&
        other.canDetectScreenSharing == canDetectScreenSharing &&
        other.platform == platform;
  }

  @override
  int get hashCode {
    return canDetectMirroring.hashCode ^
        canDetectExternalDisplay.hashCode ^
        canDetectScreenSharing.hashCode ^
        platform.hashCode;
  }
}
