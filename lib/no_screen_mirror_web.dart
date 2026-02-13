import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror_platform_interface.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class NoScreenMirrorWeb extends NoScreenMirrorPlatform {
  NoScreenMirrorWeb();

  static void registerWith(Registrar registrar) {
    NoScreenMirrorPlatform.instance = NoScreenMirrorWeb();
  }

  Timer? _pollTimer;
  final _controller = StreamController<MirrorSnapshot>.broadcast();

  @override
  Stream<MirrorSnapshot> get mirrorStream => _controller.stream;

  @override
  Future<void> startListening() async {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _controller.add(_scan());
    });
    // Emit initial state immediately.
    _controller.add(_scan());
  }

  @override
  Future<void> stopListening() async {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  MirrorSnapshot _scan() {
    bool isExtended = false;

    try {
      // screen.isExtended is Chromium 100+ only.
      // Access via JSObject since package:web may not expose it yet.
      final screen = web.window.screen;
      final jsScreen = screen as JSObject;
      final prop = jsScreen.getProperty('isExtended'.toJS);
      if (prop.isA<JSBoolean>()) {
        isExtended = (prop as JSBoolean).toDart;
      }
    } catch (_) {
      // Safari/Firefox: graceful degradation — defaults apply.
    }

    final displayCount = isExtended ? 2 : 1;

    return MirrorSnapshot(
      isScreenMirrored: false, // No browser API for AirPlay/Miracast detection
      isExternalDisplayConnected: isExtended,
      displayCount: displayCount,
    );
  }
}
