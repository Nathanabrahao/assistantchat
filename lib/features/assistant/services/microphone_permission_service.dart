import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum MicrophonePermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

final microphonePermissionServiceProvider =
    Provider<MicrophonePermissionService>(
  (ref) => const MicrophonePermissionService(),
);

class MicrophonePermissionService {
  const MicrophonePermissionService();

  Future<MicrophonePermissionResult> requestPermission() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) {
      return MicrophonePermissionResult.granted;
    }

    status = await Permission.microphone.request();

    if (status.isGranted) {
      return MicrophonePermissionResult.granted;
    }

    if (status.isPermanentlyDenied) {
      return MicrophonePermissionResult.permanentlyDenied;
    }

    return MicrophonePermissionResult.denied;
  }

  Future<bool> openSettings() {
    return openAppSettings();
  }
}