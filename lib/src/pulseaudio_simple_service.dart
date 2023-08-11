import 'dart:ffi';
import 'dart:isolate';
import 'dart:ui';

import 'package:ffi/ffi.dart';
import 'package:flutter_pulseaudio/src/models/pulse_request.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_bindings.dart';

class PulseAudioSimpleService {
  static final CPulseAudio pa = CPulseAudio(
    DynamicLibrary.open(
      "/usr/lib64/libpulse.so.0",
    ),
  );
  static const sendPortName = 'flutter_pulseaudio-simple-port';

  static void init(String name) async {
    final ret = calloc<Int>();

    final mainloop = pa.pa_mainloop_new();
    final mainloopApi = pa.pa_mainloop_get_api(mainloop);
    final context = pa.pa_context_new(mainloopApi, "PLZ".toNativeUtf8().cast());

    pa.pa_context_connect(context, nullptr, PA_CONTEXT_NOAUTOSPAWN, nullptr);

    // Run until successfully connect to PulseAudio
    while (pa.pa_context_get_state(context) != PA_CONTEXT_READY) {
      pa.pa_mainloop_iterate(mainloop, 1, ret);
    }

    final recPort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      recPort.sendPort,
      PulseAudioSimpleService.sendPortName,
    );

    await for (final PulseRequest request in recPort) {
      switch (request.type) {
        case PulseRequestType.setVolume:
          _execute(
            mainloop,
            ret,
            (p0) => _setVolume(
              request.body['device'],
              request.body['volume'],
              context,
              p0,
            ),
          );
      }
    }
  }

  static void _execute(
    Pointer<pa_mainloop> mainloop,
    Pointer<Int> ret,
    void Function(Pointer<Void>) cb,
  ) {
    using((Arena arena) {
      final completed = arena<Bool>();
      completed.value = false;

      cb(completed.cast());
      while (!completed.value) {
        pa.pa_mainloop_iterate(mainloop, 1, ret);
      }
      print("Finished job");
    });
  }

  static void _setVolume(
    String device,
    double volume,
    Pointer<pa_context> context,
    Pointer<Void> ret,
  ) {
    using((Arena arena) {
      final pVolume = arena<pa_cvolume>();
      pa.pa_cvolume_init(pVolume);
      pa.pa_cvolume_set(pVolume, 2, (volume * PA_VOLUME_NORM).ceil());

      pa.pa_context_set_sink_volume_by_name(
        context,
        device.toNativeUtf8().cast(),
        pVolume,
        Pointer.fromFunction(_set),
        ret,
      );
    });
  }

  static void _set(
    Pointer<pa_context> context,
    int success,
    Pointer<Void> userdata,
  ) {
    userdata.cast<Bool>().value = true;
  }

  // Maybe?
  //
  // static void _getServer(
  //   Pointer<pa_context> context,
  //   Pointer<pa_server_info> serverInfo,
  //   Pointer<Void> userdata,
  // ) {
  //   userdata.cast<pa_server_info>().ref = serverInfo.ref;
  // }
}
