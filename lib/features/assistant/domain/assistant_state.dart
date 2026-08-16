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
  });

  final AssistantStatus status;
  final String message;

  factory AssistantState.initial() {
    return const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Ative o assistente para começar.',
    );
  }

  bool get isActive => status == AssistantStatus.active;

  bool get isLoading => status == AssistantStatus.requestingPermission;

  AssistantState copyWith({
    AssistantStatus? status,
    String? message,
  }) {
    return AssistantState(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}