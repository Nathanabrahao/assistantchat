enum AssistantStatus {
  inactive,
  requestingPermission,
  active,
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

  /// Intensidade normalizada do áudio.
  ///
  /// 0.0 = silêncio
  /// 1.0 = intensidade máxima
  final double audioLevel;

  factory AssistantState.initial() {
    return const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Ative o assistente para começar.',
      audioLevel: 0,
    );
  }

  bool get isActive => status == AssistantStatus.active;

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