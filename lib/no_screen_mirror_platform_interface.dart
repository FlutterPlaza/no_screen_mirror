import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'no_screen_mirror_method_channel.dart';

/// The platform interface for the no_screen_mirror plugin.
///
/// Platform-specific implementations should extend this class and override
/// all methods. Use [NoScreenMirrorPlatform.instance] to access the current
/// implementation.
abstract class NoScreenMirrorPlatform extends PlatformInterface {
  /// Constructs a [NoScreenMirrorPlatform].
  NoScreenMirrorPlatform() : super(token: _token);

  static final Object _token = Object();

  static NoScreenMirrorPlatform _instance = MethodChannelNoScreenMirror();

  /// The current platform-specific implementation.
  static NoScreenMirrorPlatform get instance => _instance;

  /// Sets the platform-specific implementation to use.
  ///
  /// Platform implementations should call this in their `registerWith` method.
  static set instance(NoScreenMirrorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// A broadcast stream of [MirrorSnapshot] updates.
  ///
  /// Emits a new snapshot whenever the screen mirroring, external display,
  /// or screen sharing state changes.
  Stream<MirrorSnapshot> get mirrorStream {
    throw UnimplementedError('mirrorStream has not been implemented.');
  }

  /// Starts listening for screen mirror and display state changes.
  ///
  /// [pollingInterval] controls how often the native side polls for changes
  /// on platforms that use polling (macOS, Linux, Windows). Defaults to 2
  /// seconds.
  ///
  /// [customScreenSharingProcesses] provides additional process names to
  /// detect as screen sharing apps, supplementing the built-in list.
  Future<void> startListening({
    Duration pollingInterval = const Duration(seconds: 2),
    List<String> customScreenSharingProcesses = const [],
  }) {
    throw UnimplementedError('startListening has not been implemented.');
  }

  /// Stops listening for screen mirror and display state changes.
  ///
  /// Cancels all active timers and event subscriptions on the native side.
  Future<void> stopListening() {
    throw UnimplementedError('stopListening has not been implemented.');
  }
}
