import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class MirrorCapabilities {
  final bool canDetectMirroring;
  final bool canDetectExternalDisplay;
  final bool canDetectScreenSharing;
  final String platform;
  final String notes;

  const MirrorCapabilities({
    required this.canDetectMirroring,
    required this.canDetectExternalDisplay,
    required this.canDetectScreenSharing,
    required this.platform,
    required this.notes,
  });

  static MirrorCapabilities get current {
    if (kIsWeb) {
      return const MirrorCapabilities(
        canDetectMirroring: false,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: false,
        platform: 'web',
        notes: 'External display detection requires Chromium 100+. '
            'Safari and Firefox are not supported.',
      );
    }
    if (Platform.isAndroid) {
      return const MirrorCapabilities(
        canDetectMirroring: true,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: true,
        platform: 'android',
        notes: 'Screen sharing detection requires Android 14+ (API 34). '
            'Mirroring uses DisplayManager + MediaRouter.',
      );
    }
    if (Platform.isIOS) {
      return const MirrorCapabilities(
        canDetectMirroring: true,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: true,
        platform: 'ios',
        notes: 'Screen sharing detection uses UIScreen.isCaptured (iOS 11+). '
            'Covers AirPlay, screen recording, and screen sharing.',
      );
    }
    if (Platform.isMacOS) {
      return const MirrorCapabilities(
        canDetectMirroring: true,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: true,
        platform: 'macos',
        notes: 'Screen sharing detected via running process inspection. '
            'Uses CoreGraphics for display and mirroring detection.',
      );
    }
    if (Platform.isLinux) {
      return const MirrorCapabilities(
        canDetectMirroring: false,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: true,
        platform: 'linux',
        notes: 'Mirroring detection is not available (no kernel API). '
            'Screen sharing detected via /proc process scanning.',
      );
    }
    if (Platform.isWindows) {
      return const MirrorCapabilities(
        canDetectMirroring: true,
        canDetectExternalDisplay: true,
        canDetectScreenSharing: true,
        platform: 'windows',
        notes: 'Miracast detection via QueryDisplayConfig. '
            'Screen sharing detected via process scanning.',
      );
    }
    return const MirrorCapabilities(
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
