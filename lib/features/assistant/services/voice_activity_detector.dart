import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/voice_activity_event.dart';

final voiceActivityDetectorProvider =
    Provider<VoiceActivityDetector>((ref) {
  final detector = VoiceActivityDetector();

  ref.onDispose(detector.dispose);

  return detector;
});

class VoiceActivityDetector {
  final StreamController<VoiceActivityEvent> _eventController =
      StreamController<VoiceActivityEvent>.broadcast();

  Timer? _speechStartTimer;
  Timer? _silenceTimer;

  bool _isSpeaking = false;

  Stream<VoiceActivityEvent> get events =>
      _eventController.stream;

  bool get isSpeaking => _isSpeaking;

  // Precisará ser calibrado depois em aparelho físico.
  static const double speechStartThreshold = 0.18;

  static const double speechEndThreshold = 0.10;

  static const Duration speechStartDuration =
      Duration(milliseconds: 160);

  static const Duration silenceDuration =
      Duration(milliseconds: 700);

  void process(double audioLevel) {
    if (!_isSpeaking) {
      _processWaitingForSpeech(audioLevel);
      return;
    }

    _processCurrentSpeech(audioLevel);
  }

  void _processWaitingForSpeech(double audioLevel) {
    if (audioLevel >= speechStartThreshold) {
      _speechStartTimer ??= Timer(
        speechStartDuration,
        _startSpeech,
      );

      return;
    }

    _speechStartTimer?.cancel();
    _speechStartTimer = null;
  }

  void _processCurrentSpeech(double audioLevel) {
    if (audioLevel <= speechEndThreshold) {
      _silenceTimer ??= Timer(
        silenceDuration,
        _endSpeech,
      );

      return;
    }

    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _startSpeech() {
    if (_isSpeaking) {
      return;
    }

    _speechStartTimer = null;
    _isSpeaking = true;

    _eventController.add(
      VoiceActivityEvent.speechStarted,
    );
  }

  void _endSpeech() {
    if (!_isSpeaking) {
      return;
    }

    _silenceTimer = null;
    _isSpeaking = false;

    _eventController.add(
      VoiceActivityEvent.speechEnded,
    );
  }

  void reset() {
    _speechStartTimer?.cancel();
    _speechStartTimer = null;

    _silenceTimer?.cancel();
    _silenceTimer = null;

    _isSpeaking = false;
  }

  void dispose() {
    reset();
    _eventController.close();
  }
}