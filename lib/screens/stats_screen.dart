// lib/screens/stats_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../models/history_response.dart';
import '../utils/app_theme.dart';
import '../widgets/severity_badge.dart';
import 'detail_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _api = ApiService();

  Map<String, dynamic>? _apiStats;
  List<AnalysisResult> _historyRecords = [];
  bool _loading = false;
  String? _error;
  String _timeframe = 'All Time';

  final List<String> _timeframeOptions = ['All Time', 'This Month', 'This Week', 'Today'];

  @override
  void initState() {
    super.initState();
    _loadStats();
    ApiService.historyUpdateNotifier.addListener(_onHistoryChanged);
  }

  @override
  void dispose() {
    ApiService.historyUpdateNotifier.removeListener(_onHistoryChanged);
    super.dispose();
  }

  void _onHistoryChanged() {
    if (mounted) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final statsFuture = _api.getStats();
      final historyFuture = _api.getHistory(page: 1, perPage: 100);

      final results = await Future.wait([statsFuture, historyFuture]);

      setState(() {
        _apiStats = results[0] as Map<String, dynamic>;
        final historyRes = results[1] as HistoryResponse;
        _historyRecords = historyRes.records;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<AnalysisResult> _getFilteredRecords() {
    if (_timeframe == 'All Time') return _historyRecords;

    final now = DateTime.now();
    return _historyRecords.where((r) {
      try {
        final date = DateTime.parse(r.timestamp);
        if (_timeframe == 'Today') {
          return date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_timeframe == 'This Week') {
          final diff = now.difference(date).inDays;
          return diff >= 0 && diff < 7;
        } else if (_timeframe == 'This Month') {
          return date.year == now.year && date.month == now.month;
        }
      } catch (_) {}
      return true;
    }).toList();
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
          : _error != null && _historyRecords.isEmpty && _apiStats == null
          ? _errorView()
          : RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadStats,
        child: _statsView(),
      ),
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
    final filteredRecords = _getFilteredRecords();

    final int totalAnalyses = filteredRecords.isNotEmpty || _timeframe != 'All Time'
        ? filteredRecords.length
        : (_apiStats?['total_analyses'] as int? ?? 0);

    final healthyRecords = filteredRecords.where((r) => r.isHealthy || r.severity == 'None').toList();
    final infestedRecords = filteredRecords.where((r) => !r.isHealthy && r.severity != 'None').toList();

    final int healthyCount = filteredRecords.isNotEmpty || _timeframe != 'All Time'
        ? healthyRecords.length
        : (_apiStats?['healthy_count'] as int? ?? 0);

    final int infestedCount = filteredRecords.isNotEmpty || _timeframe != 'All Time'
        ? infestedRecords.length
        : (_apiStats?['infested_count'] as int? ?? 0);

    double avgConfidence = 0.0;
    if (filteredRecords.isNotEmpty) {
      final totalConf = filteredRecords.map((r) => r.confidence).reduce((a, b) => a + b);
      avgConfidence = totalConf / filteredRecords.length;
    } else if (_apiStats != null) {
      avgConfidence = (_apiStats!['average_confidence'] as num?)?.toDouble() ?? 0.0;
    }

    final Map<String, int> breakdown = {
      'None': 0,
      'Yellow Alert': 0,
      'Orange Alert': 0,
      'Red Alert': 0,
    };

    if (filteredRecords.isNotEmpty) {
      for (final r in filteredRecords) {
        final key = breakdown.containsKey(r.severity) ? r.severity : 'None';
        breakdown[key] = (breakdown[key] ?? 0) + 1;
      }
    } else if (_apiStats != null && _apiStats!['severity_breakdown'] is Map) {
      final apiBreakdown = _apiStats!['severity_breakdown'] as Map<String, dynamic>;
      apiBreakdown.forEach((k, v) {
        if (breakdown.containsKey(k)) breakdown[k] = (v as int? ?? 0);
      });
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeframe Filter selector ("it can be changed of course") ─────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.filter_list_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Timeframe:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeframe,
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primary),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    onChanged: (val) {
                      if (val != null) setState(() => _timeframe = val);
                    },
                    items: _timeframeOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Overview Interactive Cards ──────────────────────────────────
          Row(children: [
            Expanded(
              child: _statCard(
                label: 'Total Analyses',
                value: '$totalAnalyses',
                icon: Icons.analytics_rounded,
                color: AppTheme.primary,
                onTap: () => _showTotalAnalysesModal(
                  context,
                  total: totalAnalyses,
                  healthy: healthyCount,
                  infested: infestedCount,
                  records: filteredRecords,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Avg Confidence',
                value: '${avgConfidence.toStringAsFixed(1)}%',
                icon: Icons.speed_rounded,
                color: AppTheme.accent,
                onTap: () => _showAvgConfidenceModal(
                  context,
                  avgConfidence: avgConfidence,
                  records: filteredRecords,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _statCard(
                label: 'Healthy',
                value: '$healthyCount',
                icon: Icons.check_circle_rounded,
                color: AppTheme.healthy,
                onTap: () => _showHealthyModal(
                  context,
                  total: totalAnalyses,
                  healthyCount: healthyCount,
                  records: healthyRecords,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                label: 'Infested',
                value: '$infestedCount',
                icon: Icons.bug_report_rounded,
                color: AppTheme.high,
                onTap: () => _showInfestedModal(
                  context,
                  total: totalAnalyses,
                  infestedCount: infestedCount,
                  breakdown: breakdown,
                  records: infestedRecords,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Severity breakdown section ───────────────────────────────────
          const Text(
            'Severity Breakdown',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...['None', 'Yellow Alert', 'Orange Alert', 'Red Alert'].map((level) {
            final count = breakdown[level] ?? 0;
            final total = totalAnalyses == 0 ? 1 : totalAnalyses;
            final pct   = totalAnalyses == 0 ? 0.0 : count / total;
            final color = AppTheme.severityColor(level);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        level == 'None' ? 'Healthy (None)' : level,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '$count  (${(pct * 100).toStringAsFixed(0)}%)',
                        style: TextStyle(color: color, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.15),
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

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap for details',
                style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Sheet Modals for metric details ──────────────────────────────

  void _showTotalAnalysesModal(
      BuildContext context, {
        required int total,
        required int healthy,
        required int infested,
        required List<AnalysisResult> records,
      }) {
    final healthyPct = total > 0 ? (healthy / total * 100).toStringAsFixed(0) : '0';
    final infestedPct = total > 0 ? (infested / total * 100).toStringAsFixed(0) : '0';

    _showMetricDetailModal(
      context: context,
      title: 'Total Analyses Details',
      subtitle: 'Overview for timeframe: $_timeframe',
      icon: Icons.analytics_rounded,
      color: AppTheme.primary,
      records: records,
      summaryWidget: Card(
        color: AppTheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _modalMetricColumn('Total Scans', '$total', AppTheme.primary),
                  _modalMetricColumn('Healthy', '$healthy ($healthyPct%)', AppTheme.healthy),
                  _modalMetricColumn('Infested', '$infested ($infestedPct%)', AppTheme.high),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvgConfidenceModal(
      BuildContext context, {
        required double avgConfidence,
        required List<AnalysisResult> records,
      }) {
    final sortedRecords = List<AnalysisResult>.from(records)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final highest = sortedRecords.isNotEmpty ? sortedRecords.first.confidence : 0.0;
    final lowest = sortedRecords.isNotEmpty ? sortedRecords.last.confidence : 0.0;

    _showMetricDetailModal(
      context: context,
      title: 'Average Confidence Details',
      subtitle: 'Confidence score distribution ($_timeframe)',
      icon: Icons.speed_rounded,
      color: AppTheme.accent,
      records: sortedRecords,
      summaryWidget: Card(
        color: AppTheme.accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _modalMetricColumn('Overall Avg', '${avgConfidence.toStringAsFixed(1)}%', AppTheme.accent),
              _modalMetricColumn('Highest', '${highest.toStringAsFixed(1)}%', AppTheme.healthy),
              _modalMetricColumn('Lowest', '${lowest.toStringAsFixed(1)}%', Colors.orange),
            ],
          ),
        ),
      ),
    );
  }

  void _showHealthyModal(
      BuildContext context, {
        required int total,
        required int healthyCount,
        required List<AnalysisResult> records,
      }) {
    final pct = total > 0 ? (healthyCount / total * 100).toStringAsFixed(1) : '0.0';
    double healthyAvgConf = 0.0;
    if (records.isNotEmpty) {
      healthyAvgConf = records.map((r) => r.confidence).reduce((a, b) => a + b) / records.length;
    }

    _showMetricDetailModal(
      context: context,
      title: 'Healthy Crops Details',
      subtitle: 'Crops classified with no pest infection ($_timeframe)',
      icon: Icons.check_circle_rounded,
      color: AppTheme.healthy,
      records: records,
      summaryWidget: Card(
        color: AppTheme.healthy.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _modalMetricColumn('Healthy Scans', '$healthyCount', AppTheme.healthy),
              _modalMetricColumn('Share of Total', '$pct%', AppTheme.primary),
              _modalMetricColumn('Avg Confidence', '${healthyAvgConf.toStringAsFixed(1)}%', AppTheme.healthy),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfestedModal(
      BuildContext context, {
        required int total,
        required int infestedCount,
        required Map<String, int> breakdown,
        required List<AnalysisResult> records,
      }) {
    final pct = total > 0 ? (infestedCount / total * 100).toStringAsFixed(1) : '0.0';

    _showMetricDetailModal(
      context: context,
      title: 'Infested Crops Details',
      subtitle: 'Pest infestation detection records ($_timeframe)',
      icon: Icons.bug_report_rounded,
      color: AppTheme.high,
      records: records,
      summaryWidget: Card(
        color: AppTheme.high.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _modalMetricColumn('Infested Scans', '$infestedCount', AppTheme.high),
                  _modalMetricColumn('Share of Total', '$pct%', AppTheme.high),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _modalMetricColumn('Yellow Alert', '${breakdown['Yellow Alert'] ?? 0}', Colors.amber[800]!),
                  _modalMetricColumn('Orange Alert', '${breakdown['Orange Alert'] ?? 0}', Colors.orange[800]!),
                  _modalMetricColumn('Red Alert', '${breakdown['Red Alert'] ?? 0}', Colors.red[800]!),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  void _showMetricDetailModal({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<AnalysisResult> records,
    required Widget summaryWidget,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (sheetCtx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(icon, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        summaryWidget,
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Scan Records (${records.length})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Text(
                              'Tap record for details',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text(
                                'No matching scan records found.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          ...records.map(
                                (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _ModalRecordTile(record: r),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ModalRecordTile extends StatelessWidget {
  final AnalysisResult record;
  const _ModalRecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(record.severity);
    final cleanBaseUrl  = ApiService.baseUrl.trim();
    final String imageUrl = '$cleanBaseUrl/uploads/${record.filename}';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 44,
            height: 44,
            color: severityColor.withValues(alpha: 0.1),
            child: record.filename.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_rounded,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                size: 20,
              ),
            )
                : const Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 20),
          ),
        ),
        title: Text(
          record.originalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: Row(
          children: [
            SeverityBadge(severity: record.severity, compact: true),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                record.timestamp,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${record.confidence.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textSecondary),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailScreen(result: record)),
          );
        },
      ),
    );
  }
}