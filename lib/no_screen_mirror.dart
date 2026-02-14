import 'package:no_screen_mirror/mirror_capabilities.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';

import 'no_screen_mirror_platform_interface.dart';

class NoScreenMirror implements NoScreenMirrorPlatform {
  final _instancePlatform = NoScreenMirrorPlatform.instance;
  NoScreenMirror._();

  static NoScreenMirror get instance => NoScreenMirror._();

  static MirrorCapabilities get platformCapabilities =>
      MirrorCapabilities.current;

  @override
  Stream<MirrorSnapshot> get mirrorStream {
    return _instancePlatform.mirrorStream;
  }

  @override
  Future<void> startListening({
    Duration pollingInterval = const Duration(seconds: 2),
    List<String> customScreenSharingProcesses = const [],
  }) {
    return _instancePlatform.startListening(
      pollingInterval: pollingInterval,
      customScreenSharingProcesses: customScreenSharingProcesses,
    );
  }

  @override
  Future<void> stopListening() {
    return _instancePlatform.stopListening();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NoScreenMirror &&
            runtimeType == other.runtimeType &&
            _instancePlatform == other._instancePlatform;
  }

  @override
  int get hashCode => _instancePlatform.hashCode;
}
