final class PulseResponse {
  PulseResponseType type;
  dynamic body;

  PulseResponse({
    required this.type,
    this.body,
  });
}

enum PulseResponseType {
  /// Yielded when a output sink updates
  sinkEvent
}
