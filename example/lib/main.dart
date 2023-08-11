import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_pulseaudio/flutter_pulseaudio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ReceivePort receivePort = ReceivePort();

  @override
  void initState() {
    super.initState();
    Isolate.spawn(
      (sendPort) => PulseAudio.init(sendPort),
      receivePort.sendPort,
      debugName: "PulseAudio Isolate",
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: StreamBuilder(
            stream: receivePort,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Center(
                child: Text(
                  snapshot.data['sink'] +
                      ': ' +
                      (snapshot.data['volume'] as double).toStringAsFixed(2),
                  style: theme.textTheme.titleLarge,
                ),
              );
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () => print("Dart"),
          child: const Icon(Icons.abc),
        ),
      ),
    );
  }
}
