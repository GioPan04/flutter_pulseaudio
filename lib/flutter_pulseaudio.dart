import 'dart:ffi';
import 'dart:isolate';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_bindings.dart';

// Inspired from: https://gist.github.com/jasonwhite/1df6ee4b5039358701d2

class PulseAudioService {
  static final pa = PulseAudio(DynamicLibrary.open("/usr/lib64/libpulse.so.0"));
  static const sendPortName = 'flutter_pulseaudio-port';

  static void init(SendPort sendPort) {
    print("Creating PulseAudio connection");
    final mainloop = pa.pa_mainloop_new();
    final mainloopApi = pa.pa_mainloop_get_api(mainloop);
    final context = pa.pa_context_new(
      mainloopApi,
      'OpenCarStereo PulseAudio'.toNativeUtf8().cast(),
    );

    pa.pa_context_connect(context, nullptr, PA_CONTEXT_NOAUTOSPAWN, nullptr);

    IsolateNameServer.registerPortWithName(sendPort, sendPortName);

    pa.pa_context_set_state_callback(
      context,
      Pointer.fromFunction(_contextSetState),
      nullptr,
    );

    final ret = calloc<Int>();
    pa.pa_mainloop_run(mainloop, ret);
  }

  static void _contextSetState(
    Pointer<pa_context> context,
    Pointer<Void> userdata,
  ) {
    switch (pa.pa_context_get_state(context)) {
      case PA_CONTEXT_CONNECTING:
      case PA_CONTEXT_AUTHORIZING:
      case PA_CONTEXT_SETTING_NAME:
        break;
      case PA_CONTEXT_READY:
        print("Connection to PulseAudio established");
        // When we connect we fetch the default sink name
        pa.pa_context_get_server_info(
          context,
          Pointer.fromFunction(_serverInfoCallback),
          userdata,
        );

        pa.pa_context_set_subscribe_callback(
          context,
          Pointer.fromFunction(subscribe_callback),
          userdata,
        );
        pa.pa_context_subscribe(
          context,
          PA_SUBSCRIPTION_MASK_SINK,
          nullptr,
          userdata,
        );
        break;
      case PA_CONTEXT_TERMINATED:
        print("Connection to PulseAudio terminated");
        break;
      case PA_CONTEXT_FAILED:
        final error = pa.pa_strerror(pa.pa_context_errno(context));
        print("Connection failure: $error");
    }
  }

  static void _serverInfoCallback(
    Pointer<pa_context> context,
    Pointer<pa_server_info> serverInfo,
    Pointer<Void> userdata,
  ) {
    pa.pa_context_get_sink_info_by_name(
      context,
      serverInfo.ref.default_sink_name,
      Pointer.fromFunction(_sinkInfoCallback),
      userdata,
    );
  }

  static void _sinkInfoCallback(
    Pointer<pa_context> context,
    Pointer<pa_sink_info> sink,
    int eol,
    Pointer<Void> userdata,
  ) {
    // The first call doesn't have info of the sink
    if (sink.address != nullptr.address) {
      final sendPort = IsolateNameServer.lookupPortByName(sendPortName);

      final device = sink.ref;
      using((Arena arena) {
        final volumePointer = arena<pa_cvolume>();
        volumePointer.ref = device.volume;
        final state = {
          'sink': device.description.cast<Utf8>().toDartString(),
          'volume': pa.pa_cvolume_avg(volumePointer) / PA_VOLUME_NORM
        };
        sendPort?.send(state);
      });
    }
  }

  static void subscribe_callback(
    Pointer<pa_context> context,
    int type,
    int idx,
    Pointer<Void> userdata,
  ) {
    final facility = type & PA_SUBSCRIPTION_EVENT_FACILITY_MASK;
    Pointer<pa_operation> op = nullptr;

    switch (facility) {
      case PA_SUBSCRIPTION_EVENT_SINK:
        op = pa.pa_context_get_sink_info_by_index(
          context,
          idx,
          Pointer.fromFunction(_sinkInfoCallback),
          userdata,
        );
        break;
    }

    if (op.address != nullptr.address) pa.pa_operation_unref(op);
  }
}
