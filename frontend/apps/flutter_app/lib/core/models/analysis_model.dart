class AnalysisPoint {
  final String day;
  final double focusMinutes;
  final double onTaskPercent;

  AnalysisPoint(
      {required this.day,
      required this.focusMinutes,
      required this.onTaskPercent});

  Map<String, dynamic> toJson() => {
        'day': day,
        'focusMinutes': focusMinutes,
        'onTaskPercent': onTaskPercent,
      };
}
