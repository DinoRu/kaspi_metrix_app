class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Physical device

  static const String apiVersion = '/api/v1';

  // Auth endpoints
  static const String login = '$apiVersion/auth/login';
  static const String logout = '$apiVersion/auth/logout';
  static const String register = '$apiVersion/auth/register';
  static const String refresh = '$apiVersion/auth/refresh';
  static const String me = '$apiVersion/auth/me';

  // Meters endpoints
  static const String meters = '$apiVersion/meters/';
  static const String metersImport = '$apiVersion/meters/import';

  // Readings endpoints
  static const String readings = '$apiVersion/readings/';
  static const String readingsSync = '$apiVersion/readings/sync';

  // Photos endpoints
  static const String photosPresignedUrl = '$apiVersion/photos/presigned-url';
  static const String photosConfirm = '$apiVersion/photos/confirm';

  // Export endpoints
  static const String exportReadings = '$apiVersion/export/readings';
}
