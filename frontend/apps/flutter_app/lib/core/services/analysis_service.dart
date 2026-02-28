import '../models/analysis_model.dart';
import 'api_client.dart';

class AnalysisService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> summary(List<AnalysisPoint> points) {
    return _api.post('/analysis/summary', {
      'points': points.map((p) => p.toJson()).toList(),
    });
  }
}
