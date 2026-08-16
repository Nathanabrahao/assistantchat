abstract final class AppConfig {
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static Uri get realtimeSessionUri {
    return Uri.parse(
      '$backendBaseUrl/realtime/session',
    );
  }
}