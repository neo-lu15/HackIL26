import 'api_client.dart';

class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) {
    return _api.post('/auth/signup', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _api.post('/auth/login', {
      'username': username,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> profile(String token) {
    return _api.get('/auth/profile', token: token);
  }

  Future<void> logout(String token) async {
    await _api.post('/auth/logout', {}, token: token);
  }
}
