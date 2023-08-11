final class PulseResponse {
  PulseResponseType type;
  dynamic body;

  PulseResponse({
    required this.type,
    this.body,
  });
}

enum PulseResponseType { sinkEvent }
