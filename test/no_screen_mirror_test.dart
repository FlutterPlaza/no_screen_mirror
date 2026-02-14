import 'package:flutter_test/flutter_test.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror.dart';
import 'package:no_screen_mirror/no_screen_mirror_method_channel.dart';
import 'package:no_screen_mirror/no_screen_mirror_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNoScreenMirrorPlatform
    with MockPlatformInterfaceMixin
    implements NoScreenMirrorPlatform {
  @override
  Stream<MirrorSnapshot> get mirrorStream => const Stream.empty();

  @override
  Future<void> startListening({
    Duration pollingInterval = const Duration(seconds: 2),
    List<String> customScreenSharingProcesses = const [],
  }) {
    return Future.value();
  }

  @override
  Future<void> stopListening() {
    return Future.value();
  }
}

void main() {
  final NoScreenMirrorPlatform initialPlatform =
      NoScreenMirrorPlatform.instance;
  MockNoScreenMirrorPlatform fakePlatform = MockNoScreenMirrorPlatform();

  setUp(() {
    NoScreenMirrorPlatform.instance = fakePlatform;
  });

  tearDown(() {
    NoScreenMirrorPlatform.instance = initialPlatform;
  });

  test('\$MethodChannelNoScreenMirror is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNoScreenMirror>());
  });

  test('NoScreenMirror instance is a singleton', () {
    final instance1 = NoScreenMirror.instance;
    final instance2 = NoScreenMirror.instance;
    expect(instance1, equals(instance2));
  });

  test('mirrorStream', () {
    expect(NoScreenMirror.instance.mirrorStream,
        isInstanceOf<Stream<MirrorSnapshot>>());
  });

  test('startListening', () async {
    expect(NoScreenMirror.instance.startListening(), completes);
  });

  test('startListening with custom polling interval', () async {
    expect(
      NoScreenMirror.instance.startListening(
        pollingInterval: const Duration(seconds: 5),
      ),
      completes,
    );
  });

  test('startListening with custom processes', () async {
    expect(
      NoScreenMirror.instance.startListening(
        customScreenSharingProcesses: ['myapp', 'otherapp'],
      ),
      completes,
    );
  });

  test('startListening with all options', () async {
    expect(
      NoScreenMirror.instance.startListening(
        pollingInterval: const Duration(seconds: 3),
        customScreenSharingProcesses: ['custom.exe'],
      ),
      completes,
    );
  });

  test('stopListening', () async {
    expect(NoScreenMirror.instance.stopListening(), completes);
  });

  test('NoScreenMirror equality operator', () {
    final instance1 = NoScreenMirror.instance;
    final instance2 = NoScreenMirror.instance;

    expect(instance1 == instance2, true, reason: 'Instances should be equal');
  });

  test('NoScreenMirror hashCode consistency', () {
    final instance1 = NoScreenMirror.instance;
    final instance2 = NoScreenMirror.instance;

    expect(instance1.hashCode, instance2.hashCode);
  });
}
