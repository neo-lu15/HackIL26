import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_companion/core/services/location_service.dart';
import 'package:productivity_companion/features/settings/presentation/settings_page.dart';

void main() {
  group('SettingsPage location', () {
    testWidgets('loads and displays coordinates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            home:
                SettingsPage(locationService: _FakeLocationService.success())),
      );

      expect(find.text('Not loaded'), findsOneWidget);

      await tester.tap(find.text('Get current coordinates'));
      await tester.pump();
      await tester.pump();

      expect(find.text('12.345678, 98.765432'), findsOneWidget);
      expect(find.text('Not loaded'), findsNothing);
    });

    testWidgets('shows user-friendly error when location fetch fails',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
            home:
                SettingsPage(locationService: _FakeLocationService.failure())),
      );

      await tester.tap(find.text('Get current coordinates'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Location permission denied.'), findsOneWidget);
    });
  });
}

class _FakeLocationService extends LocationService {
  _FakeLocationService.success()
      : _result = const Coordinates(latitude: 12.345678, longitude: 98.765432),
        _error = null;

  _FakeLocationService.failure()
      : _result = null,
        _error = const LocationException(
          LocationFailureType.permissionDenied,
          'Location permission denied.',
        );

  final Coordinates? _result;
  final LocationException? _error;

  @override
  Future<Coordinates> getCurrentCoordinates() async {
    if (_error != null) throw _error!;
    return _result!;
  }
}
