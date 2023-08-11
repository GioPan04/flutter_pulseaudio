import 'dart:ffi';
import 'dart:isolate';
import 'dart:ui';
import 'package:ffi/ffi.dart';
import 'package:flutter_pulseaudio/src/pulseaudio_bindings.dart';

class PulseAudioService {
  static final pa = PulseAudio(DynamicLibrary.open("/usr/lib64/libpulse.so.0"));

  static void init(SendPort sendPort) {
    print("Creating PulseAudio connection");
    final mainloop = pa.pa_mainloop_new();
    final mainloopApi = pa.pa_mainloop_get_api(mainloop);
    final context = pa.pa_context_new(
      mainloopApi,
      'OpenCarStereo PulseAudio'.toNativeUtf8().cast(),
    );

    pa.pa_context_connect(context, nullptr, PA_CONTEXT_NOAUTOSPAWN, nullptr);
    final p = malloc<Int64>();
    print("Port: ${sendPort.nativePort}");
    p.value = sendPort.nativePort;
    IsolateNameServer.registerPortWithName(sendPort, "test");

    pa.pa_context_set_state_callback(
      context,
      Pointer.fromFunction(_contextSetState),
      p.cast<Void>(),
    );

    final ret = calloc<Int>();
    pa.pa_mainloop_run(mainloop, ret);
  }

  static void _contextSetState(
      Pointer<pa_context> context, Pointer<Void> userdata) {
    switch (pa.pa_context_get_state(context)) {
      case PA_CONTEXT_CONNECTING:
      case PA_CONTEXT_AUTHORIZING:
      case PA_CONTEXT_SETTING_NAME:
        break;
      case PA_CONTEXT_READY:
        print("Connection to PulseAudio established");
        pa.pa_context_get_server_info(
          context,
          Pointer.fromFunction(_serverInfoCallback),
          userdata,
        );
        break;
      case PA_CONTEXT_TERMINATED:
        print("Connection to PulseAudio terminated");
        break;
      case PA_CONTEXT_FAILED:
        print(
            "Connection failure: ${pa.pa_strerror(pa.pa_context_errno(context))}");
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
    if (sink.address != nullptr.address) {
      print("${userdata.cast<Int64>().value}");
      final sendPort = IsolateNameServer.lookupPortByName("test");

      sendPort?.send(sink.ref.description.cast<Utf8>().toDartString());

      // sendPort.send(sink.ref.description.cast<Utf8>().toDartString());
      print(
          "Default device: ${sink.ref.description.cast<Utf8>().toDartString()}");
    }
  }
}
