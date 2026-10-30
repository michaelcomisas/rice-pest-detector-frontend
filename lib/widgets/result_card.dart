// lib/widgets/result_card.dart

import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/pest_map_service.dart';
import '../utils/app_theme.dart';
import 'severity_badge.dart';

class ResultCard extends StatelessWidget {
  final AnalysisResult result;
  final VoidCallback? onMapTap;

  const ResultCard({
    super.key,
    required this.result,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = result.colorCode;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Color Coding Detection Header Banner ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(AppTheme.severityIcon(result.severity), color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.colorCodingLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Analysis Title & Severity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        result.status,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    SeverityBadge(severity: result.severity),
                  ],
                ),
                const SizedBox(height: 12),

                // Confidence Bar
                _label('Confidence Meter'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: result.confidence / 100,
                          backgroundColor: color.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${result.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── 3. Detect Actual Picture Location Section ─────────────────
                _label('Detected Picture Location'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result.locationName ?? 'Nueva Ecija Rice Field Region',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          result.latitude != null && result.longitude != null
                              ? '${result.latitude!.toStringAsFixed(4)}° N, ${result.longitude!.toStringAsFixed(4)}° E'
                              : '15.4827° N, 120.9698° E (Field GPS)',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                          label: const Text('Plot Outbreak Pin on Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            final lat = result.latitude ?? 15.4827;
                            final lng = result.longitude ?? 120.9698;
                            final loc = result.locationName ?? 'Nueva Ecija';

                            await PestMapService.instance.addPestReport(
                              fieldName: 'Scanned Crop (${result.status})',
                              locationName: loc,
                              latitude: lat,
                              longitude: lng,
                              pestType: result.status,
                              severity: result.severity,
                              affectedArea: 'Field Scan Block',
                              notes: 'Automatically generated from Rice Pest AI scan result.',
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Detection location plotted on Outbreak Map!'),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                              onMapTap?.call();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recommendation
                _label('Recommendation'),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    result.recommendation,
                    style: const TextStyle(height: 1.4, color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),

                // ── 2. Tips for Prevention Section ────────────────────────────
                const Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Actionable Tips for Prevention',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: result.preventionTips.map((tip) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Timestamp
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Analyzed: ${result.timestamp}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
        ),
      );
}
