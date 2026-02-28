import 'api_client.dart';

class AiService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> fillGaps({
    required List<Map<String, dynamic>> existingEvents,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> habits,
  }) {
    return _api.post('/ai/fill-gaps', {
      'existingEvents': existingEvents,
      'tasks': tasks,
      'habits': habits,
    });
  }
}
