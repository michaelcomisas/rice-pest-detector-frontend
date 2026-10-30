// lib/screens/pest_info_detail_screen.dart
// ──────────────────────────────────────────
// Full detail view for one entry in the Pest & Disease Library.

import 'package:flutter/material.dart';
import '../models/pest_info.dart';
import '../utils/app_theme.dart';

class PestInfoDetailScreen extends StatelessWidget {
  const PestInfoDetailScreen({super.key, required this.entry});

  final PestInfo entry;

  @override
  Widget build(BuildContext context) {
    final isPest = entry.isPest;
    final accent = isPest ? Colors.brown : Colors.redAccent;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.images.isNotEmpty) ...[
              _PestPhoto(path: entry.images.first, credit: entry.imageCredit),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accent.withValues(alpha: 0.15),
                    child: Icon(
                      isPest ? Icons.bug_report_rounded : Icons.coronavirus_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.localName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(entry.scientificName,
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary,
                                fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isPest ? 'PEST' : 'DISEASE',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section(
              icon: Icons.info_outline_rounded,
              title: 'Overview',
              body: entry.description,
            ),
            _section(
              icon: Icons.help_outline_rounded,
              title: isPest ? 'How It Spreads' : 'What Causes It',
              body: entry.cause,
            ),
            _section(
              icon: Icons.visibility_outlined,
              title: 'Signs & Symptoms',
              body: entry.symptoms,
            ),
            _section(
              icon: Icons.shield_outlined,
              title: 'Prevention & Safety Measures',
              body: entry.prevention,
              accent: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required String body,
    Color accent = AppTheme.textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: accent, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Shows an asset photo, or a grey placeholder if the file is missing.
Widget _pic(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.asset(
    path,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          size: 40, color: Colors.grey.shade500),
    ),
  );
}

// ── Single photo at the top of the detail screen (tap to zoom) ────────────────

class _PestPhoto extends StatelessWidget {
  const _PestPhoto({required this.path, this.credit});

  final String path;
  final String? credit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => _FullScreenPhoto(path: path)),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _pic(path),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (credit != null && credit!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              credit!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Full-screen viewer with pinch-to-zoom ──────────────────────────────────────

class _FullScreenPhoto extends StatelessWidget {
  const _FullScreenPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(child: _pic(path, fit: BoxFit.contain)),
      ),
    );
  }
}