import 'api_client.dart';

class LocationVerificationService {
  LocationVerificationService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> verify({
    required String token,
    required double lat,
    required double lng,
    required String targetAddress,
  }) {
    return _api.post(
        '/location/verify',
        {
          'lat': lat,
          'lng': lng,
          'target_address': targetAddress,
        },
        token: token);
  }

  Future<Map<String, dynamic>> history(String token) {
    return _api.get('/location/history', token: token);
  }

  Future<Map<String, dynamic>> health() {
    return _api.get('/health');
  }
}
