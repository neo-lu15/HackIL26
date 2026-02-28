import 'api_client.dart';

class CalendarService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> compareLocation(
      List<Map<String, dynamic>> events) {
    return _api.post('/calendar/compare-location', {'events': events});
  }

  Future<Map<String, dynamic>> listGoogleEvents(DateTime from, DateTime to) {
    return _api.get(
        '/calendar/google-events?timeMin=${from.toIso8601String()}&timeMax=${to.toIso8601String()}');
  }

  Future<Map<String, dynamic>> createGoogleEvent(Map<String, dynamic> event) {
    return _api.post('/calendar/google-events', event);
  }
}
