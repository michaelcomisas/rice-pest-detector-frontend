

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _stats;
  bool   _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { _loading = true; _error = null; });
    try {
      final stats = await _api.getStats();
      setState(() => _stats = stats);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
          ? _errorView()
          : _statsView(),
    );
  }

  Widget _errorView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadStats, child: const Text('Retry')),
      ],
    ),
  );

  Widget _statsView() {
    if (_stats == null) return const SizedBox.shrink();
    final breakdown = _stats!['severity_breakdown'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Overview cards ───────────────────────────────────────────────
          Row(children: [
            Expanded(child: _statCard('Total Analyses', '${_stats!['total_analyses']}',
                Icons.analytics_rounded, AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Avg Confidence',
                '${(_stats!['average_confidence'] as num).toStringAsFixed(1)}%',
                Icons.speed_rounded, AppTheme.accent)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('Healthy', '${_stats!['healthy_count']}',
                Icons.check_circle_rounded, AppTheme.healthy)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Infested', '${_stats!['infested_count']}',
                Icons.bug_report_rounded, AppTheme.high)),
          ]),
          const SizedBox(height: 20),

          // ── Severity breakdown ───────────────────────────────────────────
          const Text('Severity Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...['None', 'Yellow Alert', 'Orange Alert', 'Red Alert'].map((level) {
            final count = breakdown[level] ?? 0;
            final total = (_stats!['total_analyses'] as int?) ?? 1;
            final pct   = total == 0 ? 0.0 : (count as int) / total;
            final color = AppTheme.severityColor(level);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(level == 'None' ? 'Healthy (None)' : level,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('$count  (${(pct * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}