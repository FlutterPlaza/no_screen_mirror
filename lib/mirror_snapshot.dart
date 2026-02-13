class MirrorSnapshot {
  final bool isScreenMirrored;
  final bool isExternalDisplayConnected;
  final int displayCount;

  MirrorSnapshot({
    required this.isScreenMirrored,
    required this.isExternalDisplayConnected,
    required this.displayCount,
  });

  factory MirrorSnapshot.fromMap(Map<String, dynamic> map) {
    return MirrorSnapshot(
      isScreenMirrored: map['is_screen_mirrored'] as bool? ?? false,
      isExternalDisplayConnected:
          map['is_external_display_connected'] as bool? ?? false,
      displayCount: map['display_count'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'is_screen_mirrored': isScreenMirrored,
      'is_external_display_connected': isExternalDisplayConnected,
      'display_count': displayCount,
    };
  }

  @override
  String toString() {
    return 'MirrorSnapshot(\nisScreenMirrored: $isScreenMirrored, \nisExternalDisplayConnected: $isExternalDisplayConnected, \ndisplayCount: $displayCount\n)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MirrorSnapshot &&
        other.isScreenMirrored == isScreenMirrored &&
        other.isExternalDisplayConnected == isExternalDisplayConnected &&
        other.displayCount == displayCount;
  }

  @override
  int get hashCode {
    return isScreenMirrored.hashCode ^
        isExternalDisplayConnected.hashCode ^
        displayCount.hashCode;
  }
}
