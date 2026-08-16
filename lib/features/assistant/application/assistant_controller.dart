import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/assistant_state.dart';
import '../domain/voice_activity_event.dart';
import '../services/audio_capture_service.dart';
import '../services/microphone_permission_service.dart';
import '../services/voice_activity_detector.dart';

final assistantControllerProvider =
    NotifierProvider<AssistantController, AssistantState>(
  AssistantController.new,
);

class AssistantController extends Notifier<AssistantState> {
  StreamSubscription<double>? _audioLevelSubscription;

  StreamSubscription<VoiceActivityEvent>?
      _voiceActivitySubscription;

  @override
  AssistantState build() {
    ref.onDispose(() {
      unawaited(
        _audioLevelSubscription?.cancel(),
      );

      unawaited(
        _voiceActivitySubscription?.cancel(),
      );
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
      final permissionService = ref.read(
        microphonePermissionServiceProvider,
      );

      final result =
          await permissionService.requestPermission();

      switch (result) {
        case MicrophonePermissionResult.granted:
          await _startAudioCapture();
          break;

        case MicrophonePermissionResult.denied:
          state = const AssistantState(
            status: AssistantStatus.permissionDenied,
            message:
                'Precisamos do microfone para ouvir seus comandos.',
          );
          break;

        case MicrophonePermissionResult.permanentlyDenied:
          state = const AssistantState(
            status:
                AssistantStatus.permissionPermanentlyDenied,
            message:
                'A permissão do microfone foi bloqueada. '
                'Libere o acesso nas configurações.',
          );
          break;
      }
    } catch (_) {
      await _stopAudioCapture();

      state = const AssistantState(
        status: AssistantStatus.error,
        message:
            'Não foi possível iniciar o microfone.',
      );
    }
  }

  Future<void> _startAudioCapture() async {
    final audioService = ref.read(
      audioCaptureServiceProvider,
    );

    final voiceDetector = ref.read(
      voiceActivityDetectorProvider,
    );

    voiceDetector.reset();

    await _audioLevelSubscription?.cancel();

    await _voiceActivitySubscription?.cancel();

    await audioService.start();

    state = const AssistantState(
      status: AssistantStatus.ready,
      message: 'Aguardando você falar...',
    );

    _audioLevelSubscription =
        audioService.audioLevelStream.listen(
      (level) {
        if (!state.isActive) {
          return;
        }

        voiceDetector.process(level);

        state = state.copyWith(
          audioLevel: level,
        );
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        unawaited(
          _handleAudioError(),
        );
      },
    );

    _voiceActivitySubscription =
        voiceDetector.events.listen(
      _handleVoiceActivity,
    );
  }

  void _handleVoiceActivity(
    VoiceActivityEvent event,
  ) {
    switch (event) {
      case VoiceActivityEvent.speechStarted:
        state = state.copyWith(
          status: AssistantStatus.listening,
          message: 'Estou ouvindo...',
        );
        break;

      case VoiceActivityEvent.speechEnded:
        state = state.copyWith(
          status: AssistantStatus.ready,
          message: 'Aguardando você falar...',
        );
        break;
    }
  }

  Future<void> deactivate() async {
    if (!state.isActive) {
      return;
    }

    state = const AssistantState(
      status: AssistantStatus.inactive,
      message: 'Assistente desativado.',
    );

    await _stopAudioCapture();
  }

  Future<void> _stopAudioCapture() async {
    await _audioLevelSubscription?.cancel();
    _audioLevelSubscription = null;

    await _voiceActivitySubscription?.cancel();
    _voiceActivitySubscription = null;

    final voiceDetector = ref.read(
      voiceActivityDetectorProvider,
    );

    voiceDetector.reset();

    final audioService = ref.read(
      audioCaptureServiceProvider,
    );

    await audioService.stop();
  }

  Future<void> _handleAudioError() async {
    await _stopAudioCapture();

    state = const AssistantState(
      status: AssistantStatus.error,
      message:
          'Ocorreu um erro durante a captura do áudio.',
    );
  }

  Future<void> openSettings() async {
    final permissionService = ref.read(
      microphonePermissionServiceProvider,
    );

    await permissionService.openSettings();
  }
}