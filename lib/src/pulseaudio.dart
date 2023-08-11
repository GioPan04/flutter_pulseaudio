import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_pulseaudio/src/models/pulse_response.dart';
import 'package:flutter_pulseaudio/src/models/sink_device.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_service.dart';

// Inspired from: https://gist.github.com/jasonwhite/1df6ee4b5039358701d2

class PulseAudio {
  static final _defaultSinkStream = StreamController<SinkDevice>();
  static Stream<SinkDevice> get defaultSinkStream => _defaultSinkStream.stream;

  /// Create a new PulseAudio app with a given name
  /// This function must be called in runApp once.
  static void init(String pulseAudioName) {
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      PulseAudioService.sendPortName,
    );

    port.listen(_listen);

    Isolate.spawn<String>(
      PulseAudioService.init,
      pulseAudioName,
      debugName: "PulseAudio Isolate",
    );
  }

  static void _listen(dynamic data) {
    data = data as PulseResponse;

    switch (data.type) {
      case PulseResponseType.sinkEvent:
        _defaultSinkStream.add(data.body!);
        break;
    }
  }
}
