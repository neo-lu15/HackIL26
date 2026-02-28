import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/location_verification_service.dart';
import '../../../core/services/session_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();
  final SessionService _sessionService = SessionService();
  final LocationService _deviceLocationService = LocationService();
  final LocationVerificationService _verificationService =
      LocationVerificationService();

  final TextEditingController _usernameController =
      TextEditingController(text: 'demo_user');
  final TextEditingController _emailController =
      TextEditingController(text: 'demo@example.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'password123');

  bool _loading = false;
  bool _authLoading = false;
  bool _signupMode = false;
  bool _seededFromBackendHistory = false;

  String? _token;
  Map<String, dynamic>? _user;
  String? _error;

  final List<_PendingConfirmation> _pending = [
    _PendingConfirmation(
      title: 'Client Meeting',
      subtitle: 'Today, 2:00 PM - Zoom',
      targetAddress: 'Times Square, New York, NY',
    ),
    _PendingConfirmation(
      title: 'Design Review',
      subtitle: 'Today, 4:30 PM - Coworking Space',
      targetAddress: '350 5th Ave, New York, NY',
    ),
  ];

  final List<_VerificationSnapshot> _history = [
    for (int i = 0; i < 12; i++)
      _VerificationSnapshot(
        date: DateTime.now().subtract(Duration(days: 12 - i)),
        focusScore:
            [88, 93, 84, 82, 70, 77, 81, 66, 90, 72, 79, 87][i].toDouble(),
        onTaskPercent:
            [91, 95, 88, 86, 73, 78, 83, 70, 92, 74, 81, 89][i].toDouble(),
      ),
  ];

  @override
  void initState() {
    super.initState();
    _hydrateSession();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _hydrateSession() async {
    setState(() => _loading = true);
    try {
      final token = await _sessionService.getToken();
      final user = await _sessionService.getUser();
      if (!mounted) return;
      setState(() {
        _token = token;
        _user = user;
      });

      if (token != null && token.isNotEmpty) {
        await _refreshProfileAndHistory();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load session: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshProfileAndHistory() async {
    if (_token == null || _token!.isEmpty) return;

    try {
      final profile = await _authService.profile(_token!);
      final history = await _verificationService.history(_token!);

      final backendUser = profile['user'] as Map<String, dynamic>?;
      final historyUser = history['user'] as Map<String, dynamic>?;

      if (!mounted) return;
      setState(() {
        _user = backendUser ?? _user;
      });

      final coordinates =
          historyUser?['last_verified_coordinates'] as Map<String, dynamic>?;
      if (coordinates != null && !_seededFromBackendHistory) {
        final lat = (coordinates['latitude'] as num?)?.toDouble();
        final lng = (coordinates['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          setState(() {
            _history.add(
              _VerificationSnapshot(
                date: DateTime.now(),
                focusScore: 78,
                onTaskPercent: 80,
              ),
            );
            _seededFromBackendHistory = true;
          });
        }
      }
    } catch (_) {
      // keep local dashboard data if backend history/profile fetch fails
    }
  }

  Future<void> _authenticate() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty ||
        password.isEmpty ||
        (_signupMode && email.isEmpty)) {
      setState(() {
        _error = 'Enter username/password and email for signup.';
      });
      return;
    }

    setState(() {
      _authLoading = true;
      _error = null;
    });

    try {
      final result = _signupMode
          ? await _authService.signup(
              username: username,
              email: email,
              password: password,
            )
          : await _authService.login(username: username, password: password);

      final token = result['token'] as String?;
      final user = result['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw Exception('Backend did not return token/user data');
      }

      await _sessionService.saveSession(token: token, user: user);
      if (!mounted) return;
      setState(() {
        _token = token;
        _user = user;
      });

      await _refreshProfileAndHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _authLoading = false);
    }
  }

  Future<void> _logout() async {
    final token = _token;
    await _sessionService.clear();
    if (token != null) {
      try {
        await _authService.logout(token);
      } catch (_) {
        // Best effort logout.
      }
    }

    if (!mounted) return;
    setState(() {
      _token = null;
      _user = null;
      _error = null;
    });
  }

  Future<void> _confirmPending(_PendingConfirmation item) async {
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _error = 'Login first to confirm events with backend verification.';
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final current = await _deviceLocationService.getCurrentCoordinates();
      final verification = await _verificationService.verify(
        token: _token!,
        lat: current.latitude,
        lng: current.longitude,
        targetAddress: item.targetAddress,
      );

      final status = (verification['productivity_status'] as String? ?? 'RED')
          .toUpperCase();

      final score = switch (status) {
        'GREEN' => 94.0,
        'YELLOW' => 78.0,
        _ => 56.0,
      };
      final onTask = switch (status) {
        'GREEN' => 97.0,
        'YELLOW' => 74.0,
        _ => 42.0,
      };

      if (!mounted) return;
      setState(() {
        _history.add(
          _VerificationSnapshot(
            date: DateTime.now(),
            focusScore: score,
            onTaskPercent: onTask,
          ),
        );
        _pending.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Confirmed (${verification['productivity_status']}) - '
            '${verification['distance_meters']}m from target',
          ),
        ),
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skipPending(_PendingConfirmation item) {
    setState(() {
      _pending.remove(item);
    });
  }

  double get _onTaskPercent {
    if (_history.isEmpty) return 0;
    final total = _history.fold<double>(
      0,
      (sum, entry) => sum + entry.onTaskPercent,
    );
    return total / _history.length;
  }

  double get _weekImprovement {
    if (_history.length < 6) return 0;
    final sorted = [..._history]..sort((a, b) => a.date.compareTo(b.date));
    final midpoint = sorted.length ~/ 2;
    final firstHalf = sorted.take(midpoint).toList();
    final secondHalf = sorted.skip(midpoint).toList();

    final firstAvg = firstHalf.fold<double>(0, (s, e) => s + e.focusScore) /
        firstHalf.length;
    final secondAvg = secondHalf.fold<double>(0, (s, e) => s + e.focusScore) /
        secondHalf.length;

    if (firstAvg == 0) return 0;
    return ((secondAvg - firstAvg) / firstAvg) * 100;
  }

  List<_WeekMetric> get _weekMetrics {
    final sorted = [..._history]..sort((a, b) => a.date.compareTo(b.date));
    final chunks = <List<_VerificationSnapshot>>[];

    for (int i = sorted.length - 1; i >= 0; i -= 3) {
      final start = i - 2;
      chunks.insert(0, sorted.sublist(start < 0 ? 0 : start, i + 1));
      if (chunks.length == 4) break;
    }

    if (chunks.isEmpty) {
      return [
        _WeekMetric(label: 'Week 1', focusImprovement: 2, onTaskPercent: 72),
        _WeekMetric(label: 'Week 2', focusImprovement: 8, onTaskPercent: 79),
        _WeekMetric(label: 'Week 3', focusImprovement: 12, onTaskPercent: 86),
        _WeekMetric(label: 'Week 4', focusImprovement: 6, onTaskPercent: 90),
      ];
    }

    double previousAvg = chunks.first.fold<double>(
          0,
          (sum, e) => sum + e.focusScore,
        ) /
        chunks.first.length;

    return [
      for (int i = 0; i < chunks.length; i++)
        () {
          final week = chunks[i];
          final focusAvg =
              week.fold<double>(0, (sum, e) => sum + e.focusScore) /
                  week.length;
          final onTaskAvg =
              week.fold<double>(0, (sum, e) => sum + e.onTaskPercent) /
                  week.length;
          final change = i == 0 || previousAvg == 0
              ? 0.0
              : ((focusAvg - previousAvg) / previousAvg) * 100;
          previousAvg = focusAvg;
          return _WeekMetric(
            label: 'Week ${i + 1}',
            focusImprovement: change,
            onTaskPercent: onTaskAvg,
          );
        }(),
    ];
  }

  List<_VerificationSnapshot> get _chartHistory {
    final sorted = [..._history]..sort((a, b) => a.date.compareTo(b.date));
    return sorted.length > 14 ? sorted.sublist(sorted.length - 14) : sorted;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshProfileAndHistory,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your productivity and focus across all your activities',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (_user != null)
              Row(
                children: [
                  Chip(
                    label: Text('Signed in as ${_user?['username'] ?? 'user'}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: _logout, child: const Text('Logout')),
                ],
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            if (_token == null) _authCard(),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            _metricCard(
              title: 'On-Task Percentage',
              value: '${_onTaskPercent.round()}%',
              subtitle: 'Events completed as planned',
            ),
            const SizedBox(height: 12),
            _metricCard(
              title: 'Confirmed Events',
              value: _history.length.toString(),
              subtitle: '${_pending.length} pending confirmation',
            ),
            const SizedBox(height: 12),
            _metricCard(
              title: 'Week Improvement',
              value:
                  '${_weekImprovement >= 0 ? '+' : ''}${_weekImprovement.round()}%',
              subtitle: 'Focus improvement this week',
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth > 980;
                final width = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: width, child: _focusChartCard()),
                    SizedBox(width: width, child: _weekChartCard()),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _pendingCard(),
          ],
        ),
      ),
    );
  }

  Widget _authCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connect to Backend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (or email for login)',
              ),
            ),
            const SizedBox(height: 8),
            if (_signupMode)
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            if (_signupMode) const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: _authLoading ? null : _authenticate,
                  child: Text(_signupMode ? 'Sign up' : 'Login'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _authLoading
                      ? null
                      : () => setState(() => _signupMode = !_signupMode),
                  child: Text(
                    _signupMode ? 'Have an account? Login' : 'Create account',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _focusChartCard() {
    final points = _chartHistory;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Focus Score',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Your focus score over the past 2 weeks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ScatterChart(
                ScatterChartData(
                  minY: 0,
                  maxY: 100,
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  scatterSpots: [
                    for (int i = 0; i < points.length; i++)
                      ScatterSpot(
                        i.toDouble(),
                        points[i].focusScore,
                        dotPainter: FlDotCirclePainter(
                          radius: 4,
                          color: Colors.black,
                        ),
                      ),
                  ],
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: points.length > 6 ? 3 : 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final date = points[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(_shortDate(date)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekChartCard() {
    final weeks = _weekMetrics;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week-over-Week Improvement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Focus percentage improvement by week',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: BarChart(
                BarChartData(
                  minY: -30,
                  maxY: 100,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  barGroups: [
                    for (int i = 0; i < weeks.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 6,
                        barRods: [
                          BarChartRodData(
                            toY: weeks[i].focusImprovement,
                            width: 18,
                            color: Colors.black54,
                          ),
                          BarChartRodData(
                            toY: weeks[i].onTaskPercent,
                            width: 18,
                            color: Colors.black,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= weeks.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(weeks[index].label),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.square, size: 12, color: Colors.black54),
                SizedBox(width: 4),
                Text('Focus Improvement'),
                SizedBox(width: 16),
                Icon(Icons.square, size: 12, color: Colors.black),
                SizedBox(width: 4),
                Text('On-Task %'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Confirmations',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Events waiting for manual confirmation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Chip(label: Text('${_pending.length} pending')),
              ],
            ),
            const SizedBox(height: 12),
            if (_pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No pending events. You are all set.'),
              ),
            ..._pending.map(
              (item) => Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(item.subtitle),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed:
                            _loading ? null : () => _confirmPending(item),
                        child: const Text('Confirm'),
                      ),
                      OutlinedButton(
                        onPressed: _loading ? null : () => _skipPending(item),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}';
  }
}

class _PendingConfirmation {
  const _PendingConfirmation({
    required this.title,
    required this.subtitle,
    required this.targetAddress,
  });

  final String title;
  final String subtitle;
  final String targetAddress;
}

class _VerificationSnapshot {
  const _VerificationSnapshot({
    required this.date,
    required this.focusScore,
    required this.onTaskPercent,
  });

  final DateTime date;
  final double focusScore;
  final double onTaskPercent;
}

class _WeekMetric {
  const _WeekMetric({
    required this.label,
    required this.focusImprovement,
    required this.onTaskPercent,
  });

  final String label;
  final double focusImprovement;
  final double onTaskPercent;
}
