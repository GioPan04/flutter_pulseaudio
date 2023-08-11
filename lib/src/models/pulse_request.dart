final class PulseRequest {
  PulseRequestType type;
  dynamic body;

  PulseRequest({
    required this.type,
    this.body,
  });
}

enum PulseRequestType {
  setVolume,
}
