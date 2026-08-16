enum RealtimeEventType {
  sessionReady,
  userSpeechStarted,
  userSpeechStopped,
  responseStarted,
  assistantSpeaking,
  responseDone,
  responseCancelled,
  error,
  unknown,
}

class RealtimeEvent {
  const RealtimeEvent({
    required this.type,
    required this.rawType,
    required this.data,
  });

  final RealtimeEventType type;

  final String rawType;

  final Map<String, dynamic> data;
}