import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/assistant_state.dart';
import '../services/audio_capture_service.dart';
import '../services/microphone_permission_service.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
  AssistantController.new,
);

class AssistantController extends Notifier<AssistantState> {
  StreamSubscription<double>? _audioLevelSubscription;

  @override
  AssistantState build() {
    ref.onDispose(() {
      final subscription = _audioLevelSubscription;

      if (subscription != null) {
        unawaited(subscription.cancel());
      }
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
      audioLevel: 0,
    );

    try {
      final permissionService = ref.read(
        microphonePermissionServiceProvider,
      );

      final permissionResult =
          await permissionService.requestPermission();

      switch (permissionResult) {
        case MicrophonePermissionResult.granted:
          await _startAudioCapture();
          break;

        case MicrophonePermissionResult.denied:
          state = const AssistantState(
            status: AssistantStatus.permissionDenied,
            message:
                'Precisamos do microfone para ouvir seus comandos.',
            audioLevel: 0,
          );
          break;

        case MicrophonePermissionResult.permanentlyDenied:
          state = const AssistantState(
            status:
                AssistantStatus.permissionPermanentlyDenied,
            message:
                'A permissão do microfone foi bloqueada. '
                'Libere o acesso nas configurações.',
            audioLevel: 0,
          );
          break;
      }
    } catch (error) {
      await _stopAudioCapture();

      state = const AssistantState(
        status: AssistantStatus.error,
        message:
            'Não foi possível iniciar a captura do microfone.',
        audioLevel: 0,
      );
    }
  }

  Future<void> _startAudioCapture() async {
    final audioService = ref.read(
      audioCaptureServiceProvider,
    );

    await _audioLevelSubscription?.cancel();

    await audioService.start();

    state = const AssistantState(
      status: AssistantStatus.active,
      message: 'Estou ouvindo você.',
      audioLevel: 0,
    );

    _audioLevelSubscription =
        audioService.audioLevelStream.listen(
      (level) {
        if (!state.isActive) {
          return;
        }

        state = state.copyWith(
          audioLevel: level,
        );
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        state = const AssistantState(
          status: AssistantStatus.error,
          message:
              'Ocorreu um erro durante a captura do áudio.',
          audioLevel: 0,
        );

        unawaited(
          audioService.stop(),
        );
      },
    );
  }

  Future<void> deactivate() async {
    if (!state.isActive) {
      return;
    }

    state = const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Assistente desativado.',
      audioLevel: 0,
    );

    await _stopAudioCapture();
  }

  Future<void> _stopAudioCapture() async {
    await _audioLevelSubscription?.cancel();
    _audioLevelSubscription = null;

    final audioService = ref.read(
      audioCaptureServiceProvider,
    );

    await audioService.stop();
  }

  Future<void> openSettings() async {
    final permissionService = ref.read(
      microphonePermissionServiceProvider,
    );

    await permissionService.openSettings();
  }
}