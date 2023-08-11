# flutter_pulseaudio

Interact with [PulseAudio](https://www.freedesktop.org/wiki/Software/PulseAudio/) via Dart FFI.

Works only in Linux with PulseAudio (or pipewire-pulse) running.

## Known issues
 - In Debug mode hot reload and hot restart don't work (see #1)

## Update PulseAudio bindings
If another version of libpulse has been released with a breaking change updating the FFI bindings could be necessary.

```
$ git submodule update --init --recursive
```
```
$ flutter pub run ffigen --config ffigen.yaml
```