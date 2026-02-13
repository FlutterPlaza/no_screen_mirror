import 'package:flutter_test/flutter_test.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror_method_channel.dart';
import 'package:no_screen_mirror/no_screen_mirror_platform_interface.dart';

class BaseNoScreenMirrorPlatform extends NoScreenMirrorPlatform {}

class MockNoScreenMirrorPlatform extends NoScreenMirrorPlatform {
  @override
  Stream<MirrorSnapshot> get mirrorStream => const Stream.empty();

  @override
  Future<void> startListening() async {
    return;
  }

  @override
  Future<void> stopListening() async {
    return;
  }
}

void main() {
  final platform = MockNoScreenMirrorPlatform();

  group('NoScreenMirrorPlatform', () {
    test('default instance should be MethodChannelNoScreenMirror', () {
      expect(NoScreenMirrorPlatform.instance,
          isInstanceOf<MethodChannelNoScreenMirror>());
    });

    test('mirrorStream should not throw UnimplementedError when accessed', () {
      expect(() => platform.mirrorStream, isNot(throwsUnimplementedError));
    });

    test(
        'startListening should not throw UnimplementedError when called',
        () async {
      expect(platform.startListening(), completes);
    });

    test(
        'stopListening should not throw UnimplementedError when called',
        () async {
      expect(platform.stopListening(), completes);
    });

    test(
        'base NoScreenMirrorPlatform.mirrorStream throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenMirrorPlatform();
      expect(() => basePlatform.mirrorStream, throwsUnimplementedError);
    });

    test(
        'base NoScreenMirrorPlatform.startListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenMirrorPlatform();
      expect(
          () => basePlatform.startListening(), throwsUnimplementedError);
    });

    test(
        'base NoScreenMirrorPlatform.stopListening() throws UnimplementedError',
        () {
      final basePlatform = BaseNoScreenMirrorPlatform();
      expect(
          () => basePlatform.stopListening(), throwsUnimplementedError);
    });
  });
}
