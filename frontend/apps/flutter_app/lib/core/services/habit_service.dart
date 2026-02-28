import 'api_client.dart';

class HabitService {
  final ApiClient _api = ApiClient();

  Future<bool> shouldSuggestEvent(
      {required int streakDays,
      required double completionRateLast14Days}) async {
    final response = await _api.post('/habits/should-suggest-event', {
      'streakDays': streakDays,
      'completionRateLast14Days': completionRateLast14Days,
    });

    return response['shouldSuggest'] == true;
  }
}
