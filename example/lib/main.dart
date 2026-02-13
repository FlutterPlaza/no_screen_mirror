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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startListening() async {
    await _plugin.startListening();
    _subscription = _plugin.mirrorStream.listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('No Screen Mirror')),
        body: Padding(
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
                      Text(
                        'Display Count: ${_snapshot?.displayCount ?? '-'}',
                        style: Theme.of(context).textTheme.bodyLarge,
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
    );
  }

  Widget _statusRow(String label, bool active) {
    return Row(
      children: [
        Icon(
          Icons.circle,
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
}
