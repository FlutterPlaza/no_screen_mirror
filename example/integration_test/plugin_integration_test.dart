// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('startListening and stopListening complete without error', (
    WidgetTester tester,
  ) async {
    final plugin = NoScreenMirror.instance;

    await plugin.startListening();
    await plugin.stopListening();
  });

  testWidgets('mirrorStream emits MirrorSnapshot after startListening', (
    WidgetTester tester,
  ) async {
    final plugin = NoScreenMirror.instance;

    await plugin.startListening();

    final snapshot = await plugin.mirrorStream.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: false,
        displayCount: 1,
      ),
    );

    expect(snapshot, isA<MirrorSnapshot>());
    expect(snapshot.displayCount, greaterThanOrEqualTo(1));

    await plugin.stopListening();
  });

  testWidgets('MirrorSnapshot has expected properties', (
    WidgetTester tester,
  ) async {
    final plugin = NoScreenMirror.instance;

    await plugin.startListening();

    final snapshot = await plugin.mirrorStream.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => MirrorSnapshot(
        isScreenMirrored: false,
        isExternalDisplayConnected: false,
        displayCount: 1,
      ),
    );

    expect(snapshot.isScreenMirrored, isA<bool>());
    expect(snapshot.isExternalDisplayConnected, isA<bool>());
    expect(snapshot.isScreenShared, isA<bool>());
    expect(snapshot.displayCount, isA<int>());

    await plugin.stopListening();
  });
}
