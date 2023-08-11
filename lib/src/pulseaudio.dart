import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_pulseaudio/src/pulseaudio_service.dart';

// Inspired from: https://gist.github.com/jasonwhite/1df6ee4b5039358701d2

class PulseAudio {
  static late ReceivePort port;

  /// Create a new PulseAudio app with a given name
  /// This function must be called in runApp once.
  static void init(String pulseAudioName) {
    port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      PulseAudioService.sendPortName,
    );

    Isolate.spawn<String>(
      PulseAudioService.init,
      pulseAudioName,
      debugName: "PulseAudio Isolate",
    );
  }
}
