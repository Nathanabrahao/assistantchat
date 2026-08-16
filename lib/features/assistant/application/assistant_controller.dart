import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/assistant_state.dart';
import '../services/microphone_permission_service.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
  AssistantController.new,
);

class AssistantController extends Notifier<AssistantState> {
  @override
  AssistantState build() {
    return AssistantState.initial();
  }

  Future<void> activate() async {
    if (state.isLoading || state.isActive) {
      return;
    }

    state = const AssistantState(
      status: AssistantStatus.requestingPermission,
      message: 'Solicitando acesso ao microfone...',
    );

    try {
      final permissionService = ref.read(
        microphonePermissionServiceProvider,
      );

      final result = await permissionService.requestPermission();

      if (!ref.mounted) {
        return;
      }

      switch (result) {
        case MicrophonePermissionResult.granted:
          state = const AssistantState(
            status: AssistantStatus.active,
            message: 'Assistente ativo e pronto.',
          );

        case MicrophonePermissionResult.denied:
          state = const AssistantState(
            status: AssistantStatus.permissionDenied,
            message:
                'Precisamos do microfone para ouvir seus comandos.',
          );

        case MicrophonePermissionResult.permanentlyDenied:
          state = const AssistantState(
            status: AssistantStatus.permissionPermanentlyDenied,
            message:
                'A permissão do microfone foi bloqueada. '
                'Libere o acesso nas configurações.',
          );
      }
    } catch (_) {
      state = const AssistantState(
        status: AssistantStatus.error,
        message: 'Não foi possível ativar o assistente.',
      );
    }
  }

  void deactivate() {
    state = const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Assistente desativado.',
    );
  }

  Future<void> openSettings() async {
    final permissionService = ref.read(
      microphonePermissionServiceProvider,
    );

    await permissionService.openSettings();
  }
}