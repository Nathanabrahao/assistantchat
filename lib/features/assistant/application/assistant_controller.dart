import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/assistant_state.dart';
import '../domain/realtime_event.dart';
import '../services/microphone_permission_service.dart';
import '../services/realtime_service.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

class AssistantController extends Notifier<AssistantState> {
  StreamSubscription<RealtimeEvent>? _realtimeSubscription;

  @override
  AssistantState build() {
    ref.onDispose(() {
      unawaited(_realtimeSubscription?.cancel());
    });

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
      final permissionService = ref.read(microphonePermissionServiceProvider);

      final result = await permissionService.requestPermission();

      switch (result) {
        case MicrophonePermissionResult.granted:
          await _connectRealtime();
          break;

        case MicrophonePermissionResult.denied:
          state = const AssistantState(
            status: AssistantStatus.permissionDenied,
            message: 'Precisamos do microfone para conversar.',
          );
          break;

        case MicrophonePermissionResult.permanentlyDenied:
          state = const AssistantState(
            status: AssistantStatus.permissionPermanentlyDenied,
            message: 'A permissão do microfone foi bloqueada.',
          );
          break;
      }
    } catch (_) {
      state = const AssistantState(
        status: AssistantStatus.error,
        message: 'Não foi possível ativar o assistente.',
      );
    }
  }

  Future<void> _connectRealtime() async {
    final realtimeService = ref.read(realtimeServiceProvider);

    await _realtimeSubscription?.cancel();

    _realtimeSubscription = realtimeService.events.listen(_handleRealtimeEvent);

    state = const AssistantState(
      status: AssistantStatus.connecting,
      message: 'Conectando à inteligência artificial...',
    );

    try {
      await realtimeService.connect();

      if (state.status == AssistantStatus.connecting) {
        state = const AssistantState(
          status: AssistantStatus.ready,
          message: 'Pode falar.',
        );
      }
    } catch (error) {
      await realtimeService.disconnect();

      state = AssistantState(
        status: AssistantStatus.error,
        message: 'Falha ao conectar à IA: $error',
      );
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.sessionReady:
        state = const AssistantState(
          status: AssistantStatus.ready,
          message: 'Pode falar.',
        );
        break;

      case RealtimeEventType.userSpeechStarted:
        state = const AssistantState(
          status: AssistantStatus.listening,
          message: 'Estou ouvindo você...',
        );

        break;

      case RealtimeEventType.userSpeechStopped:
        state = const AssistantState(
          status: AssistantStatus.thinking,
          message: 'Pensando...',
        );
        break;

      case RealtimeEventType.responseStarted:
        state = const AssistantState(
          status: AssistantStatus.thinking,
          message: 'Preparando resposta...',
        );
        break;

      case RealtimeEventType.assistantSpeaking:
        state = const AssistantState(
          status: AssistantStatus.speaking,
          message: 'Respondendo...',
        );
        break;

      case RealtimeEventType.responseDone:
        if (state.isListening || state.status == AssistantStatus.thinking) {
          break;
        }

        state = const AssistantState(
          status: AssistantStatus.ready,
          message: 'Pode falar.',
        );

        break;

      case RealtimeEventType.responseCancelled:
        if (state.isListening || state.status == AssistantStatus.thinking) {
          break;
        }

        state = const AssistantState(
          status: AssistantStatus.ready,
          message: 'Pode falar.',
        );

        break;

      case RealtimeEventType.error:
        state = const AssistantState(
          status: AssistantStatus.error,
          message: 'Ocorreu um erro na sessão Realtime.',
        );
        break;

      case RealtimeEventType.unknown:
        break;
    }
  }

  Future<void> deactivate() async {
    final realtimeService = ref.read(realtimeServiceProvider);

    state = const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Assistente desativado.',
    );

    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    await realtimeService.disconnect();
  }

  Future<void> openSettings() async {
    final permissionService = ref.read(microphonePermissionServiceProvider);

    await permissionService.openSettings();
  }
}
