import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/location_verification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, LocationService? locationService})
      : _locationService = locationService;

  final LocationService? _locationService;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocationVerificationService _verificationService =
      LocationVerificationService();
  late final LocationService _locationService;

  bool _loadingCoordinates = false;
  Coordinates? _coordinates;
  String? _locationError;
  String? _backendStatus;

  @override
  void initState() {
    super.initState();
    _locationService = widget._locationService ?? LocationService();
  }

  Future<void> _fetchCoordinates() async {
    setState(() {
      _loadingCoordinates = true;
      _locationError = null;
    });

    try {
      final coordinates = await _locationService.getCurrentCoordinates();
      if (!mounted) return;
      setState(() => _coordinates = coordinates);
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _locationError = 'Unexpected error while loading location.');
    } finally {
      if (mounted) setState(() => _loadingCoordinates = false);
    }
  }

  Future<void> _checkBackendHealth() async {
    setState(() => _backendStatus = 'Checking backend...');
    try {
      final response = await _verificationService.health();
      if (!mounted) return;
      setState(() => _backendStatus =
          response['message'] as String? ?? 'Backend reachable');
    } catch (e) {
      if (!mounted) return;
      setState(() => _backendStatus = 'Backend check failed: $e');
    }
  }

  String _coordinateText() {
    if (_coordinates == null) return 'Not loaded';
    return _coordinates!.format();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Backend Base URL'),
                  subtitle: Text(AppConfig.backendBaseUrl),
                ),
                const ListTile(
                  title: Text('Location Source'),
                  subtitle: Text('Device GPS via Geolocator'),
                ),
                ListTile(
                  title: const Text('Current Coordinates'),
                  subtitle: Text(_coordinateText()),
                ),
                if (_locationError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _locationError!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: _loadingCoordinates ? null : _fetchCoordinates,
                    child: Text(
                      _loadingCoordinates
                          ? 'Getting coordinates...'
                          : 'Get current coordinates',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: _checkBackendHealth,
                    child: const Text('Check backend connection'),
                  ),
                ),
                if (_backendStatus != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Text(_backendStatus!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
