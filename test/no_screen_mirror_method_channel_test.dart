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

    test('startListening', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == startListeningConst) {
          return null;
        }
        return null;
      });

      await platform.startListening();
      expect(true, true);
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
      };
      final snapshot = MirrorSnapshot.fromMap(map);
      expect(snapshot.isScreenMirrored, true);
      expect(snapshot.isExternalDisplayConnected, true);
      expect(snapshot.displayCount, 2);
    });

    test('fromMap with defaults', () {
      final snapshot = MirrorSnapshot.fromMap({});
      expect(snapshot.isScreenMirrored, false);
      expect(snapshot.isExternalDisplayConnected, false);
      expect(snapshot.displayCount, 1);
    });

    test('fromMap with null values uses defaults', () {
      final map = <String, dynamic>{
        'is_screen_mirrored': null,
        'is_external_display_connected': null,
        'display_count': null,
      };
      final snapshot = MirrorSnapshot.fromMap(map);
      expect(snapshot.isScreenMirrored, false);
      expect(snapshot.isExternalDisplayConnected, false);
      expect(snapshot.displayCount, 1);
    });

    test('toMap', () {
      final snapshot = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: true,
        displayCount: 3,
      );
      final map = snapshot.toMap();
      expect(map['is_screen_mirrored'], true);
      expect(map['is_external_display_connected'], true);
      expect(map['display_count'], 3);
    });

    test('equality operator', () {
      final snapshot1 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
      );
      final snapshot2 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
      );
      final snapshot3 = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
      );

      expect(snapshot1 == snapshot2, true);
      expect(snapshot1 == snapshot3, false);
    });

    test('hashCode', () {
      final snapshot1 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
      );
      final snapshot2 = MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: true,
        displayCount: 2,
      );
      final snapshot3 = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
      );

      expect(snapshot1.hashCode, snapshot2.hashCode);
      expect(snapshot1.hashCode, isNot(snapshot3.hashCode));
    });

    test('toString', () {
      final snapshot = MirrorSnapshot(
        isScreenMirrored: true,
        isExternalDisplayConnected: false,
        displayCount: 1,
      );
      final string = snapshot.toString();
      expect(
          string,
          'MirrorSnapshot(\nisScreenMirrored: true, \nisExternalDisplayConnected: false, \ndisplayCount: 1\n)');
    });
  });
}
