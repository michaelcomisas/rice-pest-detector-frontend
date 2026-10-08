

import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/severity_badge.dart';

class DetailScreen extends StatelessWidget {
  final AnalysisResult result;
  const DetailScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.severityColor(result.severity);


    final cleanBaseUrl = ApiService.baseUrl.trim();
    final String imageUrl = '$cleanBaseUrl/uploads/${result.filename}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Detail', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [

                  SizedBox(
                    width: double.infinity,
                    height: 200,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [

                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: result.filename.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      color: color.withValues(alpha: 0.5),
                                      size: 48,
                                    ),
                                  );
                                },
                              )
                                  : Center(
                                child: Icon(Icons.image_rounded, color: color, size: 48),
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          right: -6,
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              AppTheme.severityIcon(result.severity),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result.status,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                  ),
                  const SizedBox(height: 6),
                  SeverityBadge(severity: result.severity),
                ],
              ),
            ),
            const SizedBox(height: 16),


            Row(children: [
              Expanded(child: _metricCard('Confidence', '${result.confidence.toStringAsFixed(1)}%', Icons.percent)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard('Detections', '${result.detections}', Icons.pest_control_rounded)),
            ]),
            const SizedBox(height: 16),


            _infoCard(
              icon: Icons.tips_and_updates_rounded,
              title: 'Recommendation',
              content: result.recommendation,
              iconColor: AppTheme.accent,
            ),
            const SizedBox(height: 12),


            _infoCard(
              icon: Icons.info_outline_rounded,
              title: 'Details',
              content: 'File: ${result.originalName}\nAnalyzed: ${result.timestamp}',
              iconColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
            Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String   title,
    required String   content,
    Color iconColor = AppTheme.primary,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(content,
                      style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}