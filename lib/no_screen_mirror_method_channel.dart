import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:no_screen_mirror/constants.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';

import 'no_screen_mirror_platform_interface.dart';

/// Method channel implementation of [NoScreenMirrorPlatform].
///
/// Communicates with native platform code via a [MethodChannel] for commands
/// and an [EventChannel] for streaming mirror state updates.
class MethodChannelNoScreenMirror extends NoScreenMirrorPlatform {
  /// The method channel used to invoke native methods.
  @visibleForTesting
  final methodChannel = const MethodChannel(mirrorMethodChannel);

  /// The event channel used to receive native mirror state events.
  @visibleForTesting
  final eventChannel = const EventChannel(mirrorEventChannel);

  @override
  Stream<MirrorSnapshot> get mirrorStream {
    return eventChannel.receiveBroadcastStream().map((event) =>
        MirrorSnapshot.fromMap(jsonDecode(event) as Map<String, dynamic>));
  }

  @override
  Future<void> startListening({
    Duration pollingInterval = const Duration(seconds: 2),
    List<String> customScreenSharingProcesses = const [],
  }) {
    return methodChannel.invokeMethod<void>(startListeningConst, {
      'pollingIntervalMs': pollingInterval.inMilliseconds,
      if (customScreenSharingProcesses.isNotEmpty)
        'customProcesses': customScreenSharingProcesses,
    });
  }

  @override
  Future<void> stopListening() {
    return methodChannel.invokeMethod<void>(stopListeningConst);
  }
}
