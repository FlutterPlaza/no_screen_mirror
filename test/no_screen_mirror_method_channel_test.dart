import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_screen_mirror/constants.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannelNoScreenMirror platform;

  setUp(() {
    platform = MethodChannelNoScreenMirror();
  });

  group('MethodChannelNoScreenMirror', () {
    const MethodChannel channel = MethodChannel(mirrorMethodChannel);

    test('startListening sends default args', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startListeningConst) {
          capturedArgs = Map<String, dynamic>.from(
              methodCall.arguments as Map<Object?, Object?>);
          return null;
        }
        return null;
      });

      await platform.startListening();
      expect(capturedArgs, isNotNull);
      expect(capturedArgs!['pollingIntervalMs'], 2000);
      expect(capturedArgs!.containsKey('customProcesses'), false);
    });

    test('startListening sends custom polling interval', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startListeningConst) {
          capturedArgs = Map<String, dynamic>.from(
              methodCall.arguments as Map<Object?, Object?>);
          return null;
        }
        return null;
      });

      await platform.startListening(
        pollingInterval: const Duration(seconds: 5),
      );
      expect(capturedArgs!['pollingIntervalMs'], 5000);
    });

    test('startListening sends custom process names', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startListeningConst) {
          capturedArgs = Map<String, dynamic>.from(
              methodCall.arguments as Map<Object?, Object?>);
          return null;
        }
        return null;
      });

      await platform.startListening(
        customScreenSharingProcesses: ['myapp', 'otherapp'],
      );
      expect(capturedArgs!['customProcesses'], ['myapp', 'otherapp']);
    });

    test('startListening omits empty custom processes', () async {
      Map<String, dynamic>? capturedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startListeningConst) {
          capturedArgs = Map<String, dynamic>.from(
              methodCall.arguments as Map<Object?, Object?>);
          return null;
        }
        return null;
      });

      await platform.startListening();
      expect(capturedArgs!.containsKey('customProcesses'), false);
    });

    test('stopListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == stopListeningConst) {
          return null;
        }
        return null;
      });

      await platform.stopListening();
      expect(true, true);
    });
  });

  group('MirrorSnapshot', () {
    test('fromMap', () {
      final map = {
        'is_screen_mirrored': true,
        'is_external_display_connected': true,
        'display_count': 2,
        'is_screen_shared': true,
      };
      final snapshot = MirrorSnapshot.fromMap(map);
      expect(snapshot.isScreenMirrored, true);
      expect(snapshot.isExternalDisplayConnected, true);
      expect(snapshot.displayCount, 2);
      expect(snapshot.isScreenShared, true);
    });

    test('fromMap with defaults', () {
      final snapshot = MirrorSnapshot.fromMap({});
      expect(snapshot.isScreenMirrored, false);
      expect(snapshot.isExternalDisplayConnected, false);
      expect(snapshot.displayCount, 1);
      expect(snapshot.isScreenShared, false);
    });

    test('fromMap with null values uses defaults', () {
      final map = <String, dynamic>{
        'is_screen_mirrored': null,
        'is_external_display_connected': null,
        'display_count': null,
        'is_screen_shared': null,
      };
      final snapshot = MirrorSnapshot.fromMap(map);
      expect(snapshot.isScreenMirrored, false);
      expect(snapshot.isExternalDisplayConnected, false);
      expect(snapshot.displayCount, 1);
      expect(snapshot.isScreenShared, false);
    });

    test('toMap', () {
      final snapshot = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: true,
        displayCount: 3,
        isScreenShared: true,
      );
      final map = snapshot.toMap();
      expect(map['is_screen_mirrored'], true);
      expect(map['is_external_display_connected'], true);
      expect(map['display_count'], 3);
      expect(map['is_screen_shared'], true);
    });

    test('equality operator', () {
      final snapshot1 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
        isScreenShared: true,
      );
      final snapshot2 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
        isScreenShared: true,
      );
      final snapshot3 = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
        isScreenShared: false,
      );
      final snapshot4 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
        isScreenShared: false,
      );

      expect(snapshot1 == snapshot2, true);
      expect(snapshot1 == snapshot3, false);
      expect(snapshot1 == snapshot4, false);
    });

    test('hashCode', () {
      final snapshot1 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
        isScreenShared: true,
      );
      final snapshot2 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
        isScreenShared: true,
      );
      final snapshot3 = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
        isScreenShared: false,
      );

      expect(snapshot1.hashCode, snapshot2.hashCode);
      expect(snapshot1.hashCode, isNot(snapshot3.hashCode));
    });

    test('toString', () {
      final snapshot = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
        isScreenShared: true,
      );
      final string = snapshot.toString();
      expect(string,
          'MirrorSnapshot(\nisScreenMirrored: true, \nisExternalDisplayConnected: false, \ndisplayCount: 1, \nisScreenShared: true\n)');
    });

    test('roundtrip fromMap/toMap preserves data', () {
      final original = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: true,
        displayCount: 3,
        isScreenShared: true,
      );
      final roundtripped = MirrorSnapshot.fromMap(original.toMap());
      expect(roundtripped, original);
    });
  });
}
