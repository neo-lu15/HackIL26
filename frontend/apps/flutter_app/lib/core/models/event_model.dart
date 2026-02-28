class EventModel {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final List<String> gcalLocations;
  final bool requiresManualConfirmation;

  EventModel({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.gcalLocations = const [],
    this.requiresManualConfirmation = false,
  });
}
