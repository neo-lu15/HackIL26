import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get backendBaseUrl =>
      dotenv.env['FLUTTER_BACKEND_BASE_URL'] ?? 'http://localhost:3000/api';
}
