// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../models/history_response.dart';
import '../utils/app_theme.dart';
import '../widgets/severity_badge.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api          = ApiService();
  final _scrollCtrl   = ScrollController();

  List<AnalysisResult> _records  = [];
  bool   _loading     = false;
  bool   _loadingMore = false;
  int    _page        = 1;
  int    _totalPages  = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialFetch();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // Pure initial fetch loader cleanly isolated
  Future<void> _initialFetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _records = [];
      _page = 1;
    });

    try {
      final res = await _api.getHistory(page: 1);
      setState(() {
        _records = res.records;
        _totalPages = res.pages;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Paginated layout loader
  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _totalPages) return;

    setState(() => _loadingMore = true);
    final nextPage = _page + 1;

    try {
      final res = await _api.getHistory(page: nextPage);
      setState(() {
        _page = nextPage; // Only increment internal page tracker on true API success
        _records.addAll(res.records);
        _totalPages = res.pages;
      });
    } on ApiException catch (e) {
      // Show non-blocking snackbar warning so the user isn't kicked out of the view
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more records: ${e.message}')),
        );
      }
    } finally {
      setState(() => _loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis History', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initialFetch,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null && _records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _initialFetch, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: AppTheme.textSecondary),
            SizedBox(height: 12),
            Text('No analyses yet. Start by capturing a live crop scan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _initialFetch,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(12),
        itemCount: _records.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          if (i >= _records.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            );
          }
          return _HistoryTile(record: _records[i]);
        },
      ),
    );
  }
}


class _HistoryTile extends StatelessWidget {
  final AnalysisResult record;
  const _HistoryTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(record.severity);


    final cleanBaseUrl = ApiService.baseUrl.trim();
    final String imageUrl = '$cleanBaseUrl/uploads/${record.filename}';

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        leading: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [

              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: severityColor.withValues(alpha: 0.1),
                      child: record.filename.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                          );
                        },

                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          );
                        },
                      )
                          : const Center(
                        child: Icon(Icons.image_rounded, color: AppTheme.textSecondary, size: 20),
                      ),
                    ),
                  ),
                ),
              ),


              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: severityColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    AppTheme.severityIcon(record.severity),
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          record.originalName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            SeverityBadge(severity: record.severity, compact: true),
            const SizedBox(height: 4),
            Text(
              record.timestamp,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${record.confidence.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                  color: AppTheme.primary),
            ),
            const Text('confidence',
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(result: record)),
        ),
      ),
    );
  }
}