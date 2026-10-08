

import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../utils/app_theme.dart';
import 'severity_badge.dart';

class ResultCard extends StatelessWidget {
  final AnalysisResult result;
  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(result.severity);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(AppTheme.severityIcon(result.severity), color: color, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.status,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
                SeverityBadge(severity: result.severity),
              ],
            ),
            const Divider(height: 24),


            _label('Confidence Score'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: result.confidence / 100,
                      backgroundColor: color.withOpacity(0.15),
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

            // Detections
            _label('Detections found'),
            Text('${result.detections} area(s) flagged',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Recommendation
            _label('Recommendation'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(result.recommendation,
                  style: const TextStyle(height: 1.5, color: AppTheme.textPrimary)),
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
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500)),
  );
}