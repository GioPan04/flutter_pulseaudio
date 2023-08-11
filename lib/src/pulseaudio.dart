import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_pulseaudio/src/models/pulse_request.dart';
import 'package:flutter_pulseaudio/src/models/pulse_response.dart';
import 'package:flutter_pulseaudio/src/models/sink_device.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_service.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_simple_service.dart';

// Inspired from: https://gist.github.com/jasonwhite/1df6ee4b5039358701d2

class PulseAudio {
  static final _defaultSinkStream = StreamController<SinkDevice>();
  static SinkDevice? _lastSinkDevice;

  /// Subscribe to this stream to be notified when the default sink device it's
  /// updated (like volume, default sink device changed)
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
      PulseAudioSimpleService.init,
      pulseAudioName,
      debugName: "PulseAudio Control Isolate",
    );

    Isolate.spawn<String>(
      PulseAudioService.init,
      pulseAudioName,
      debugName: "PulseAudio Isolate",
    );
  }

  static void setVolume(double volume) {
    IsolateNameServer.lookupPortByName(PulseAudioSimpleService.sendPortName)
        ?.send(PulseRequest(
      type: PulseRequestType.setVolume,
      body: {
        'device': _lastSinkDevice!.name,
        'volume': volume,
      },
    ));
  }

  static void _listen(dynamic data) {
    data = data as PulseResponse;

    switch (data.type) {
      // TODO: Check if the volume or name was updated. We could receive an event even for other things.
      case PulseResponseType.sinkEvent:
        _defaultSinkStream.add(data.body!);
        _lastSinkDevice = data.body;
        break;
      default:
    }
  }
}
