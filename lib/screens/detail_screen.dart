// lib/screens/detail_screen.dart

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
    final color = result.colorCode;
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
            // ── 1. Color Coding Detection Header Banner ───────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(AppTheme.severityIcon(result.severity), color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.colorCodingLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Image Preview & Status Container
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
            const SizedBox(height: 14),

            // Confidence Metric
            _metricCard('Confidence Score', '${result.confidence.toStringAsFixed(1)}%', Icons.percent, color),
            const SizedBox(height: 14),

            // ── 3. Detect Actual Picture Location Card ─────────────────────
            _infoCard(
              icon: Icons.location_on_rounded,
              title: 'Detected Picture Location',
              content: '${result.locationName ?? 'Nueva Ecija Rice Field Region'}\nGPS Coordinates: ${result.latitude != null && result.longitude != null ? '${result.latitude!.toStringAsFixed(4)}° N, ${result.longitude!.toStringAsFixed(4)}° E' : '15.4827° N, 120.9698° E'}',
              iconColor: AppTheme.primary,
            ),
            const SizedBox(height: 12),

            // Recommendation Card
            _infoCard(
              icon: Icons.health_and_safety_rounded,
              title: 'Recommendation',
              content: result.recommendation,
              iconColor: color,
            ),
            const SizedBox(height: 14),

            // ── 2. Tips for Prevention Card ────────────────────────────────
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Actionable Tips for Prevention',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...result.preventionTips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String content,
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(content, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
