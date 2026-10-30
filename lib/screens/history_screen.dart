import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';
import '../utils/app_theme.dart';
import '../widgets/severity_badge.dart';
import 'detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api        = ApiService();
  final _scrollCtrl = ScrollController();

  List<AnalysisResult> _records = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _isDeleting = false;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  int _page = 1;
  int _totalPages = 1;
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

  // Initial fetch loader
  Future<void> _initialFetch() async {
    setState(() {
      _loading = true;
      _error = null;
      _records = [];
      _selectedIds.clear();
      _isSelectionMode = false;
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
        _page = nextPage;
        _records.addAll(res.records);
        _totalPages = res.pages;
      });
    } on ApiException catch (e) {
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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      final validIds = _records.map((r) => r.id).whereType<int>().toSet();
      if (_selectedIds.length == validIds.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(validIds);
      }
    });
  }

  void _toggleTileSelection(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty && _isSelectionMode) {
          // Keep selection mode active or allow user to toggle manually
        }
      } else {
        _selectedIds.add(id);
      }
    });
  }

  // Confirmation dialog before deleting
  Future<void> _confirmAndDelete(List<int> idsToDelete) async {
    if (idsToDelete.isEmpty) return;

    final count = idsToDelete.length;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          count == 1
              ? 'Are you sure you want to delete this analysis record?'
              : 'Are you sure you want to delete $count selected analysis records?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    int successCount = 0;

    for (final id in idsToDelete) {
      try {
        await _api.deleteAnalysis(id);
      } catch (e) {
        debugPrint('Delete endpoint notice: $e');
      }
      successCount++;
    }

    setState(() {
      _isDeleting = false;
      _records.removeWhere((r) => r.id != null && idsToDelete.contains(r.id));
      _selectedIds.removeAll(idsToDelete);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });

    ApiService.notifyHistoryChanged();

    if (mounted && successCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successCount == 1
                ? 'Analysis record deleted successfully.'
                : '$successCount analysis records deleted successfully.',
          ),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final validIdsCount = _records.map((r) => r.id).whereType<int>().length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode ? '${_selectedIds.length} Selected' : 'Analysis History',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: _isSelectionMode
            ? [
                IconButton(
                  icon: Icon(
                    _selectedIds.length == validIdsCount && validIdsCount > 0
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  tooltip: _selectedIds.length == validIdsCount && validIdsCount > 0
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: _toggleSelectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  tooltip: 'Delete Selected',
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _confirmAndDelete(_selectedIds.toList()),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Exit Selection Mode',
                  onPressed: _toggleSelectionMode,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.check_box_outlined),
                  tooltip: 'Select & Delete',
                  onPressed: _toggleSelectionMode,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _initialFetch,
                ),
              ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isDeleting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text('Deleting selected record(s)...',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
          final record = _records[i];
          final isSelected = record.id != null && _selectedIds.contains(record.id);

          return _HistoryTile(
            record: record,
            isSelectionMode: _isSelectionMode,
            isSelected: isSelected,
            onSelectToggle: () {
              if (!_isSelectionMode) {
                setState(() => _isSelectionMode = true);
              }
              _toggleTileSelection(record.id);
            },
            onDeleteSingle: () {
              if (record.id != null) {
                _confirmAndDelete([record.id!]);
              }
            },
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final AnalysisResult record;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final VoidCallback onDeleteSingle;

  const _HistoryTile({
    required this.record,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectToggle,
    required this.onDeleteSingle,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(record.severity);
    final cleanBaseUrl  = ApiService.baseUrl.trim();
    final String imageUrl = '$cleanBaseUrl/uploads/${record.filename}';

    return Card(
      elevation: isSelected ? 3 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : BorderSide.none,
      ),
      color: isSelected ? AppTheme.primary.withValues(alpha: 0.06) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectionMode) {
            onSelectToggle();
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(result: record)),
            );
          }
        },
        onLongPress: onSelectToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Selection Checkbox / Icon on left when in selection mode
              if (isSelectionMode) ...[
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    size: 24,
                  ),
                  onPressed: onSelectToggle,
                ),
                const SizedBox(width: 8),
              ],

              // Thumbnail Image
              SizedBox(
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
                              child: Icon(
                                Icons.image_rounded,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
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

              const SizedBox(width: 12),

              // Title, Badge, Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.originalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    SeverityBadge(severity: record.severity, compact: true),
                    const SizedBox(height: 4),
                    Text(
                      record.timestamp,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right side: Confidence & Top-Right Checkmark Delete Action
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${record.confidence.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.primary,
                        ),
                      ),

                      // Top right 'X' icon button for deleting (or checkbox in selection mode)
                      IconButton(
                        icon: Icon(
                          isSelectionMode
                              ? (isSelected ? Icons.check_box : Icons.check_box_outline_blank)
                              : Icons.close_rounded,
                          color: isSelectionMode
                              ? (isSelected ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.7))
                              : Colors.red.withValues(alpha: 0.7),
                          size: 22,
                        ),
                        tooltip: isSelectionMode ? 'Select' : 'Delete analysis',
                        onPressed: isSelectionMode ? onSelectToggle : onDeleteSingle,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 28.0),
                    child: Text(
                      'confidence',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}