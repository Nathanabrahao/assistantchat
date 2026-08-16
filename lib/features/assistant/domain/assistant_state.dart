enum AssistantStatus {
  inactive,

  requestingPermission,

  ready,

  listening,

  permissionDenied,

  permissionPermanentlyDenied,

  error,
}

class AssistantState {
  const AssistantState({
    required this.status,
    required this.message,
    this.audioLevel = 0,
  });

  final AssistantStatus status;

  final String message;

  final double audioLevel;

  factory AssistantState.initial() {
    return const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Ative o assistente para começar.',
    );
  }

  bool get isActive =>
      status == AssistantStatus.ready ||
      status == AssistantStatus.listening;

  bool get isListening =>
      status == AssistantStatus.listening;

  bool get isLoading =>
      status == AssistantStatus.requestingPermission;

  AssistantState copyWith({
    AssistantStatus? status,
    String? message,
    double? audioLevel,
  }) {
    return AssistantState(
      status: status ?? this.status,
      message: message ?? this.message,
      audioLevel: audioLevel ?? this.audioLevel,
    );
  }
}