import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/realtime_event.dart';

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();

  ref.onDispose(() {
    unawaited(service.dispose());
  });

  return service;
});

class RealtimeService {
  final http.Client _httpClient = http.Client();

  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  RTCPeerConnection? _peerConnection;

  RTCDataChannel? _dataChannel;

  MediaStream? _localStream;

  RTCVideoRenderer? _remoteRenderer;

  Completer<void>? _sessionReadyCompleter;

  bool _connected = false;

  Stream<RealtimeEvent> get events => _eventController.stream;

  bool get isConnected => _connected;

  Future<void> connect() async {
    if (_connected || _peerConnection != null) {
      return;
    }

    _sessionReadyCompleter = Completer<void>();

    try {
      await _prepareRemoteAudio();

      final peerConnection = await createPeerConnection({
        'sdpSemantics': 'unified-plan',
      });

      _peerConnection = peerConnection;

      _configurePeerConnection(peerConnection);

      await _attachMicrophone(peerConnection);

      await _createDataChannel(peerConnection);

      final offer = await peerConnection.createOffer();

      await peerConnection.setLocalDescription(offer);

      final sdp = offer.sdp;

      if (sdp == null || sdp.isEmpty) {
        throw StateError('Não foi possível gerar o SDP local.');
      }

      final response = await _httpClient.post(
        AppConfig.realtimeSessionUri,
        headers: {'Content-Type': 'application/sdp'},
        body: sdp,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Backend retornou ${response.statusCode}: '
          '${response.body}',
        );
      }

      final answer = RTCSessionDescription(response.body, 'answer');

      await peerConnection.setRemoteDescription(answer);

      await _sessionReadyCompleter!.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException('A sessão Realtime não ficou pronta.');
        },
      );

      _connected = true;
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  Future<void> _prepareRemoteAudio() async {
    final renderer = RTCVideoRenderer();

    await renderer.initialize();

    _remoteRenderer = renderer;

    await Helper.setSpeakerphoneOnButPreferBluetooth();
  }

  void _configurePeerConnection(RTCPeerConnection peerConnection) {
    peerConnection.onTrack = (event) {
      if (kDebugMode) {
        debugPrint(
          '[WebRTC] Remote track recebida: '
          '${event.track.kind}',
        );
      }

      if (event.streams.isEmpty) {
        return;
      }

      _remoteRenderer?.srcObject = event.streams.first;
    };

    peerConnection.onConnectionState = (connectionState) {
      if (kDebugMode) {
        debugPrint(
          '[WebRTC] Connection state: '
          '$connectionState',
        );
      }

      if (connectionState ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _emit(
          const RealtimeEvent(
            type: RealtimeEventType.error,
            rawType: 'webrtc.connection.failed',
            data: {},
          ),
        );
      }
    };
  }

  Future<void> _attachMicrophone(RTCPeerConnection peerConnection) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    });

    _localStream = stream;

    final audioTracks = stream.getAudioTracks();

    if (audioTracks.isEmpty) {
      throw StateError('Nenhuma faixa de áudio foi encontrada.');
    }

    for (final track in audioTracks) {
      await peerConnection.addTrack(track, stream);
    }
  }

  Future<void> _createDataChannel(RTCPeerConnection peerConnection) async {
    final config = RTCDataChannelInit()..ordered = true;

    final channel = await peerConnection.createDataChannel(
      'oai-events',
      config,
    );

    _dataChannel = channel;

    channel.onMessage = _handleDataChannelMessage;
  }

  void _handleDataChannelMessage(RTCDataChannelMessage message) {
    if (message.isBinary) {
      return;
    }

    try {
      final decoded = jsonDecode(message.text);

      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final rawType = decoded['type']?.toString() ?? '';

      if (kDebugMode) {
        debugPrint('[Realtime] $rawType');
      }

      final event = _mapEvent(rawType, decoded);

      if (event.type == RealtimeEventType.sessionReady) {
        final completer = _sessionReadyCompleter;

        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
      }

      _emit(event);
    } catch (_) {
      // Evento inválido não deve derrubar a sessão.
    }
  }

  RealtimeEvent _mapEvent(String rawType, Map<String, dynamic> data) {
    final type = switch (rawType) {
      'session.created' => RealtimeEventType.sessionReady,

      'input_audio_buffer.speech_started' =>
        RealtimeEventType.userSpeechStarted,

      'input_audio_buffer.speech_stopped' =>
        RealtimeEventType.userSpeechStopped,

      'response.created' => RealtimeEventType.responseStarted,

      // WebSocket / compatibilidade
      'response.output_audio.delta' => RealtimeEventType.assistantSpeaking,

      // Mais útil para acompanhar uma sessão WebRTC
      'response.output_audio_transcript.delta' =>
        RealtimeEventType.assistantSpeaking,

      'response.done' => RealtimeEventType.responseDone,

      'response.cancelled' => RealtimeEventType.responseCancelled,

      'error' => RealtimeEventType.error,

      _ => RealtimeEventType.unknown,
    };

    return RealtimeEvent(type: type, rawType: rawType, data: data);
  }

  void _emit(RealtimeEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  Future<void> disconnect() async {
    _connected = false;

    _sessionReadyCompleter = null;

    final dataChannel = _dataChannel;
    _dataChannel = null;

    if (dataChannel != null) {
      await dataChannel.close();
    }

    final localStream = _localStream;
    _localStream = null;

    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        await track.stop();
      }

      await localStream.dispose();
    }

    final peerConnection = _peerConnection;
    _peerConnection = null;

    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }

    final renderer = _remoteRenderer;
    _remoteRenderer = null;

    if (renderer != null) {
      renderer.srcObject = null;
      await renderer.dispose();
    }

    await Helper.clearAndroidCommunicationDevice();
  }

  Future<void> dispose() async {
    await disconnect();

    _httpClient.close();

    await _eventController.close();
  }

  void sendEvent(Map<String, dynamic> event) {
    final channel = _dataChannel;

    if (channel == null) {
      return;
    }

    if (channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      return;
    }

    channel.send(RTCDataChannelMessage(jsonEncode(event)));
  }

  void cancelResponse() {
    sendEvent({'type': 'response.cancel'});
  }

  void clearOutputAudio() {
    sendEvent({'type': 'output_audio_buffer.clear'});
  }
}
