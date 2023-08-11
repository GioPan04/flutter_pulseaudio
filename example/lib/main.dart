import 'package:flutter/material.dart';
import 'package:flutter_pulseaudio/flutter_pulseaudio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PulseAudio.init('Flutter PulseAudio Example');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: StreamBuilder(
            stream: PulseAudio.port,
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
