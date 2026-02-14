/// A point-in-time snapshot of the device's screen mirroring and display state.
///
/// Emitted by [NoScreenMirror.mirrorStream] whenever the state changes.
class MirrorSnapshot {
  /// Whether the screen is being mirrored (e.g. via AirPlay or Miracast).
  final bool isScreenMirrored;

  /// Whether an external display is connected (e.g. HDMI or USB-C).
  final bool isExternalDisplayConnected;

  /// The total number of displays detected, including the built-in screen.
  final int displayCount;

  /// Whether the screen is being shared in a video call or recording.
  final bool isScreenShared;

  /// Creates a [MirrorSnapshot] with the given display state values.
  MirrorSnapshot({
    required this.isScreenMirrored,
    required this.isExternalDisplayConnected,
    required this.displayCount,
    this.isScreenShared = false,
  });

  /// Creates a [MirrorSnapshot] from a platform channel map.
  ///
  /// Missing or null values default to `false` for booleans and `1` for
  /// [displayCount].
  factory MirrorSnapshot.fromMap(Map<String, dynamic> map) {
    return MirrorSnapshot(
      isScreenMirrored: map['is_screen_mirrored'] as bool? ?? false,
      isExternalDisplayConnected:
          map['is_external_display_connected'] as bool? ?? false,
      displayCount: map['display_count'] as int? ?? 1,
      isScreenShared: map['is_screen_shared'] as bool? ?? false,
    );
  }

  /// Converts this snapshot to a map suitable for platform channel serialization.
  Map<String, dynamic> toMap() {
    return {
      'is_screen_mirrored': isScreenMirrored,
      'is_external_display_connected': isExternalDisplayConnected,
      'display_count': displayCount,
      'is_screen_shared': isScreenShared,
    };
  }

  @override
  String toString() {
    return 'MirrorSnapshot(\nisScreenMirrored: $isScreenMirrored, \nisExternalDisplayConnected: $isExternalDisplayConnected, \ndisplayCount: $displayCount, \nisScreenShared: $isScreenShared\n)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MirrorSnapshot &&
        other.isScreenMirrored == isScreenMirrored &&
        other.isExternalDisplayConnected == isExternalDisplayConnected &&
        other.displayCount == displayCount &&
        other.isScreenShared == isScreenShared;
  }

  @override
  int get hashCode {
    return isScreenMirrored.hashCode ^
        isExternalDisplayConnected.hashCode ^
        displayCount.hashCode ^
        isScreenShared.hashCode;
  }
}
