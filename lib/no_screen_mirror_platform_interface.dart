import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'no_screen_mirror_method_channel.dart';

abstract class NoScreenMirrorPlatform extends PlatformInterface {
  NoScreenMirrorPlatform() : super(token: _token);

  static final Object _token = Object();

  static NoScreenMirrorPlatform _instance = MethodChannelNoScreenMirror();

  static NoScreenMirrorPlatform get instance => _instance;

  static set instance(NoScreenMirrorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<MirrorSnapshot> get mirrorStream {
    throw UnimplementedError('mirrorStream has not been implemented.');
  }

  Future<void> startListening({
    Duration pollingInterval = const Duration(seconds: 2),
    List<String> customScreenSharingProcesses = const [],
  }) {
    throw UnimplementedError('startListening has not been implemented.');
  }

  Future<void> stopListening() {
    throw UnimplementedError('stopListening has not been implemented.');
  }
}
