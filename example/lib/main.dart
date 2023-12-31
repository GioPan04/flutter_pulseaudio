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
            stream: PulseAudio.defaultSinkStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${snapshot.data?.name}: ${snapshot.data?.volume.toStringAsFixed(2)}",
                      style: theme.textTheme.titleLarge,
                    ),
                    Slider(
                      value: snapshot.data!.volume,
                      onChanged: (value) => PulseAudio.setVolume(value),
                    )
                  ],
                ),
              );
            }),
      ),
    );
  }
}
