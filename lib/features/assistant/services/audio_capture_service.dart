import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

final audioCaptureServiceProvider = Provider<AudioCaptureService>((ref) {
  final service = AudioCaptureService();

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});

class AudioCaptureService {
  final AudioRecorder _recorder = AudioRecorder();

  final StreamController<double> _audioLevelController =
      StreamController<double>.broadcast();

  StreamSubscription<Uint8List>? _audioSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  bool _isRunning = false;

  double _smoothedLevel = 0;

  Stream<double> get audioLevelStream => _audioLevelController.stream;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    final hasPermission = await _recorder.hasPermission(
      request: false,
    );

    if (!hasPermission) {
      throw StateError(
        'Permissão de microfone não concedida.',
      );
    }

    try {
      final audioStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 24000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
      );

      _isRunning = true;

      // Mantemos o stream PCM sendo consumido.
      // Na próxima etapa esses bytes serão enviados para a IA.
      _audioSubscription = audioStream.listen(
        (_) {},
        onError: _audioLevelController.addError,
      );

      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(
            const Duration(milliseconds: 80),
          )
          .listen(
        (amplitude) {
          final normalized = _normalizeDb(
            amplitude.current,
          );

          // Suaviza mudanças bruscas para não deixar
          // a interface "tremendo".
          _smoothedLevel =
              (_smoothedLevel * 0.70) + (normalized * 0.30);

          if (!_audioLevelController.isClosed) {
            _audioLevelController.add(
              _smoothedLevel,
            );
          }
        },
        onError: _audioLevelController.addError,
      );
    } catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _audioSubscription?.cancel();
    _audioSubscription = null;

    _isRunning = false;
    _smoothedLevel = 0;

    if (!_audioLevelController.isClosed) {
      _audioLevelController.add(0);
    }
  }

  double _normalizeDb(double db) {
    if (!db.isFinite) {
      return 0;
    }

    const minimumDb = -60.0;
    const maximumDb = 0.0;

    final normalized =
        (db - minimumDb) / (maximumDb - minimumDb);

    return normalized.clamp(0.0, 1.0).toDouble();
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _audioLevelController.close();
  }
}