import 'dart:async';

import 'package:flutter/material.dart';
import 'package:no_screen_mirror/mirror_snapshot.dart';
import 'package:no_screen_mirror/no_screen_mirror.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _plugin = NoScreenMirror.instance;
  StreamSubscription<MirrorSnapshot>? _subscription;
  MirrorSnapshot? _snapshot;
  bool _isListening = false;
  bool _showMirrorWarning = false;
  bool _showShareWarning = false;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    await _plugin.startListening(pollingInterval: const Duration(seconds: 2));
    _subscription = _plugin.mirrorStream.listen((snapshot) {
      if (!mounted) return;
      final wasMirrored = _snapshot?.isScreenMirrored ?? false;
      final wasShared = _snapshot?.isScreenShared ?? false;

      setState(() {
        _snapshot = snapshot;

        // Show warning banner when state transitions to active
        if (snapshot.isScreenMirrored && !wasMirrored) {
          _showMirrorWarning = true;
        } else if (!snapshot.isScreenMirrored) {
          _showMirrorWarning = false;
        }

        if (snapshot.isScreenShared && !wasShared) {
          _showShareWarning = true;
        } else if (!snapshot.isScreenShared) {
          _showShareWarning = false;
        }
      });
    });
    setState(() {
      _isListening = true;
    });
  }

  Future<void> _stopListening() async {
    await _plugin.stopListening();
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _isListening = false;
      _showMirrorWarning = false;
      _showShareWarning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final capabilities = NoScreenMirror.platformCapabilities;

    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('No Screen Mirror')),
        body: Column(
          children: [
            // Warning banners
            if (_showMirrorWarning)
              MaterialBanner(
                content: const Text('Screen mirroring detected!'),
                leading: const Icon(Icons.warning_amber, color: Colors.orange),
                backgroundColor: Colors.orange.shade50,
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _showMirrorWarning = false),
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            if (_showShareWarning)
              MaterialBanner(
                content: const Text('Screen sharing detected!'),
                leading: const Icon(Icons.warning_amber, color: Colors.red),
                backgroundColor: Colors.red.shade50,
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _showShareWarning = false),
                    child: const Text('DISMISS'),
                  ),
                ],
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _statusRow(
                              'Screen Mirrored',
                              _snapshot?.isScreenMirrored ?? false,
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              'External Display',
                              _snapshot?.isExternalDisplayConnected ?? false,
                            ),
                            const SizedBox(height: 8),
                            _statusRow(
                              'Screen Shared',
                              _snapshot?.isScreenShared ?? false,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Display Count: ${_snapshot?.displayCount ?? '-'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Platform Capabilities',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            _capabilityRow(
                              'Mirroring Detection',
                              capabilities.canDetectMirroring,
                            ),
                            const SizedBox(height: 8),
                            _capabilityRow(
                              'External Display Detection',
                              capabilities.canDetectExternalDisplay,
                            ),
                            const SizedBox(height: 8),
                            _capabilityRow(
                              'Screen Sharing Detection',
                              capabilities.canDetectScreenSharing,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              capabilities.notes,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _isListening ? null : _startListening,
                            child: const Text('Start Listening'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isListening ? _stopListening : null,
                            child: const Text('Stop Listening'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(String label, bool active) {
    return Row(
      children: [
        Icon(
          active ? Icons.circle : Icons.circle_outlined,
          size: 12,
          color: active ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text(
          active ? 'Yes' : 'No',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: active ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _capabilityRow(String label, bool supported) {
    return Row(
      children: [
        Icon(
          supported ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: supported ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
