// lib/screens/offline_queue_screen.dart
// ─────────────────────────────────────
// Captures saved while offline. Each signed-in user has their own queue,
// stored under a key that includes their mobile number.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'detail_screen.dart';

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  final _api = ApiService();
  List<String> _offlineImages = [];
  bool _isAnalyzing = false;
  String? _currentlyAnalyzingPath;

  /// Same key that home_screen.dart saves to, unique per user.
  String get _queueKey => AuthService.instance.scopedKey('offline_pests_queue');

  @override
  void initState() {
    super.initState();
    _loadOfflineQueue();
  }

  Future<void> _loadOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _offlineImages = List<String>.from(prefs.getStringList(_queueKey) ?? []);
    });
  }

  Future<void> _removeFromQueue(String path) async {
    final prefs = await SharedPreferences.getInstance();
    _offlineImages.remove(path);
    await prefs.setStringList(_queueKey, _offlineImages);
    if (mounted) setState(() {});
  }

  Future<void> _analyzeOfflineImage(String path) async {
    File file = File(path);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Original image file not found on device.')),
        );
      }
      _removeFromQueue(path);
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _currentlyAnalyzingPath = path;
    });

    try {
      // ApiService automatically uploads this under the signed-in user.
      final result = await _api.analyzeImage(file);

      await _removeFromQueue(path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis successful! Added to History.'), backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(result: result)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e. Signal might still be weak.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _currentlyAnalyzingPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Saved Captures')),
      body: _offlineImages.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.cloud_done_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No offline images pending', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            Text('All scanned crops have been uploaded.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      )
          : Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _offlineImages.length,
            itemBuilder: (context, index) {
              final path = _offlineImages[index];
              final isThisLoading = _currentlyAnalyzingPath == path;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(path),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Offline Capture', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('Waiting for internet connection...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      isThisLoading
                          ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                          : IconButton(
                        icon: const Icon(Icons.cloud_upload_rounded, color: AppTheme.primary),
                        onPressed: _isAnalyzing ? null : () => _analyzeOfflineImage(path),
                        tooltip: 'Analyze Now',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: _isAnalyzing ? null : () => _removeFromQueue(path),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_isAnalyzing)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            )
        ],
      ),
    );
  }
}