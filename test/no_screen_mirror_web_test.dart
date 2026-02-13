@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:no_screen_mirror/no_screen_mirror_platform_interface.dart';
import 'package:no_screen_mirror/no_screen_mirror_web.dart';

void main() {
  group('NoScreenMirrorWeb', () {
    late NoScreenMirrorWeb webPlugin;

    setUp(() {
      webPlugin = NoScreenMirrorWeb();
    });

    test('is a NoScreenMirrorPlatform', () {
      expect(webPlugin, isA<NoScreenMirrorPlatform>());
    });

    test('mirrorStream is a broadcast stream', () {
      final stream = webPlugin.mirrorStream;
      // Broadcast streams allow multiple listeners without error.
      stream.listen((_) {});
      stream.listen((_) {});
    });

    test('startListening completes without error', () async {
      await expectLater(webPlugin.startListening(), completes);
      // Clean up.
      await webPlugin.stopListening();
    });

    test('stopListening completes without error', () async {
      await expectLater(webPlugin.stopListening(), completes);
    });

    test('stopListening after startListening completes without error',
        () async {
      await webPlugin.startListening();
      await expectLater(webPlugin.stopListening(), completes);
    });
  });
}
