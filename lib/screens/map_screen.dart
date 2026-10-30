// lib/screens/map_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pest_report.dart';
import '../services/pest_map_service.dart';
import '../utils/app_theme.dart';
import '../widgets/severity_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _pestMapService = PestMapService.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  List<PestReport> _reports = [];
  bool _loading = true;
  String _selectedSeverityFilter = 'All';
  String _selectedPestFilter = 'All';

  // Search Results State
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _activeSearchedLocation;

  // Map view transform controls
  double _zoomLevel = 1.0;
  Offset _mapOffset = Offset.zero;
  Offset _dragStart = Offset.zero;

  // Bounding box strictly for Zamboanga Sibugay Province, Philippines
  // Lat: 7.20 to 8.10 N, Lng: 122.20 to 123.30 E
  static const double _minLat = 7.20;
  static const double _maxLat = 8.10;
  static const double _minLng = 122.20;
  static const double _maxLng = 123.30;

  @override
  void initState() {
    super.initState();
    _loadData();
    _pestMapService.reportsNotifier.addListener(_onReportsUpdated);
  }

  @override
  void dispose() {
    _pestMapService.reportsNotifier.removeListener(_onReportsUpdated);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onReportsUpdated() {
    if (mounted) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final reports = await _pestMapService.getAllMapReports();
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<PestReport> get _filteredReports {
    return _reports.where((r) {
      if (_selectedSeverityFilter != 'All' && r.severity != _selectedSeverityFilter) {
        return false;
      }
      if (_selectedPestFilter != 'All' && !r.pestType.contains(_selectedPestFilter)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _onSearchQueryChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    final matches = PestMapService.presetLocations.where((loc) {
      final name = (loc['name'] as String).toLowerCase();
      return name.contains(q);
    }).toList();

    setState(() {
      _searchResults = matches;
    });
  }

  void _selectSearchedLocation(Map<String, dynamic> location, Size canvasSize) {
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    final name = location['name'] as String;

    _searchCtrl.text = name;
    _searchResults.clear();
    _activeSearchedLocation = location;

    // Project coordinates to offset and center map
    final normalizedX = (lng - _minLng) / (_maxLng - _minLng);
    final normalizedY = 1.0 - ((lat - _minLat) / (_maxLat - _minLat));

    final baseDx = normalizedX * canvasSize.width;
    final baseDy = normalizedY * canvasSize.height;

    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    setState(() {
      _zoomLevel = 2.2;
      _mapOffset = Offset(centerX - baseDx, centerY - baseDy);
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Map centered directly on $name!'),
        backgroundColor: AppTheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetMapTransform() {
    setState(() {
      _zoomLevel = 1.0;
      _mapOffset = Offset.zero;
      _activeSearchedLocation = null;
      _searchCtrl.clear();
      _searchResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.satellite_alt_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Zamboanga Sibugay Map', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Center on My Field (Ipil)',
            onPressed: _centerOnMyField,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset View',
            onPressed: _resetMapTransform,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                // ── Filter Bar ─────────────────────────────────────────────
                _buildFilterBar(),

                // ── Interactive Map Canvas View ────────────────────────────
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);

                      return Stack(
                        children: [
                          // Map gesture area
                          GestureDetector(
                            onPanStart: (details) => _dragStart = details.localPosition - _mapOffset,
                            onPanUpdate: (details) {
                              setState(() {
                                _mapOffset = details.localPosition - _dragStart;
                              });
                            },
                            child: Container(
                              color: const Color(0xFF0F2B48), // Satellite Sea Blue
                              child: Stack(
                                children: [
                                  // Satellite Map Custom Painter for Zamboanga Sibugay
                                  CustomPaint(
                                    size: size,
                                    painter: _ZamboangaSibugaySatellitePainter(
                                      zoom: _zoomLevel,
                                      offset: _mapOffset,
                                    ),
                                  ),

                                  // Pest Outbreak Pins
                                  ..._filteredReports.map((report) {
                                    final pos = _projectLatLngToOffset(
                                      report.latitude,
                                      report.longitude,
                                      size,
                                    );

                                    return Positioned(
                                      left: pos.dx - 20,
                                      top: pos.dy - 38,
                                      child: GestureDetector(
                                        onTap: () => _showReportDetails(report),
                                        child: _buildMapPin(report),
                                      ),
                                    );
                                  }),

                                  // Active Searched Location Pin Marker
                                  if (_activeSearchedLocation != null) ...[
                                    () {
                                      final lat = _activeSearchedLocation!['lat'] as double;
                                      final lng = _activeSearchedLocation!['lng'] as double;
                                      final pos = _projectLatLngToOffset(lat, lng, size);

                                      return Positioned(
                                        left: pos.dx - 22,
                                        top: pos.dy - 44,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent,
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _activeSearchedLocation!['name'] as String,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.location_searching_rounded,
                                              color: Colors.redAccent,
                                              size: 34,
                                            ),
                                          ],
                                        ),
                                      );
                                    }(),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // ── Top Floating Search Bar ───────────────────────
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 12,
                            child: Column(
                              children: [
                                Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    onChanged: _onSearchQueryChanged,
                                    decoration: InputDecoration(
                                      hintText: 'Search field location in Sibugay (e.g. Ipil, Titay)...',
                                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                                      suffixIcon: _searchCtrl.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.close_rounded),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() {
                                                  _searchResults.clear();
                                                  _activeSearchedLocation = null;
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),

                                // Live Search Autocomplete Dropdown List
                                if (_searchResults.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final item = _searchResults[i];
                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                                          title: Text(
                                            item['name'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          subtitle: const Text('Zamboanga Sibugay Municipality', style: TextStyle(fontSize: 10.5)),
                                          onTap: () => _selectSearchedLocation(item, size),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ── Zoom Controls Overlay ────────────────────────────
                          Positioned(
                            right: 14,
                            bottom: 80,
                            child: Column(
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'zoom_in',
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  onPressed: () {
                                    setState(() {
                                      _zoomLevel = math.min(_zoomLevel + 0.3, 3.5);
                                    });
                                  },
                                  child: const Icon(Icons.add),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'zoom_out',
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  onPressed: () {
                                    setState(() {
                                      _zoomLevel = math.max(_zoomLevel - 0.3, 0.7);
                                    });
                                  },
                                  child: const Icon(Icons.remove),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'reset_view',
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppTheme.primary,
                                  onPressed: _resetMapTransform,
                                  child: const Icon(Icons.center_focus_strong_rounded),
                                ),
                              ],
                            ),
                          ),

                          // ── Map Legend Overlay ───────────────────────────────
                          Positioned(
                            left: 12,
                            bottom: 12,
                            child: _buildMapLegend(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_pest_report',
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Report Disease/Pest', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: _showAddReportModal,
      ),
    );
  }

  // ── Project Lat/Lng to Screen Offset ──────────────────────────────────────
  Offset _projectLatLngToOffset(double lat, double lng, Size canvasSize) {
    final normalizedX = (lng - _minLng) / (_maxLng - _minLng);
    final normalizedY = 1.0 - ((lat - _minLat) / (_maxLat - _minLat));

    final baseDx = normalizedX * canvasSize.width;
    final baseDy = normalizedY * canvasSize.height;

    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    final transformedDx = (baseDx - centerX) * _zoomLevel + centerX + _mapOffset.dx;
    final transformedDy = (baseDy - centerY) * _zoomLevel + centerY + _mapOffset.dy;

    return Offset(transformedDx, transformedDy);
  }

  // ── Map Pin Widget ────────────────────────────────────────────────────────
  Widget _buildMapPin(PestReport report) {
    final isMe = report.isCurrentUser;
    final color = AppTheme.severityColor(report.severity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isMe ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMe)
                const Padding(
                  padding: EdgeInsets.only(right: 3),
                  child: Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                ),
              Text(
                isMe ? 'My Field' : report.fieldName,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: isMe ? 42 : 36,
              color: color,
            ),
            Positioned(
              top: isMe ? 6 : 5,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPestIconData(report.pestType),
                  size: isMe ? 14 : 12,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getPestIconData(String pest) {
    if (pest.contains('Stem Borer')) return Icons.bug_report_rounded;
    if (pest.contains('Blast')) return Icons.coronavirus_rounded;
    if (pest.contains('Planthopper') || pest.contains('Leafhopper')) return Icons.pest_control_rounded;
    if (pest.contains('Snail') || pest.contains('Kuhol')) return Icons.shield_rounded;
    if (pest.contains('Bacterial') || pest.contains('Blight')) return Icons.warning_amber_rounded;
    if (pest.contains('Healthy')) return Icons.check_circle_rounded;
    return Icons.grass_rounded;
  }

  // ── Filter Bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSeverityFilter,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  items: ['All', 'None', 'Yellow Alert', 'Orange Alert', 'Red Alert']
                      .map((opt) => DropdownMenuItem(value: opt, child: Text('Severity: $opt')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSeverityFilter = val);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPestFilter,
                  isExpanded: true,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                  items: ['All', 'Stem Borer', 'Blast', 'Planthopper', 'Blight', 'Tungro', 'Snail', 'Healthy']
                      .map((opt) => DropdownMenuItem(value: opt, child: Text('Pest: $opt')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPestFilter = val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Map Legend ────────────────────────────────────────────────────────────
  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Zamboanga Sibugay Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.5)),
          const SizedBox(height: 4),
          _legendItem('Healthy', AppTheme.healthy),
          _legendItem('Yellow Alert', AppTheme.severityColor('Yellow Alert')),
          _legendItem('Orange Alert', AppTheme.severityColor('Orange Alert')),
          _legendItem('Red Alert', AppTheme.severityColor('Red Alert')),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  void _centerOnMyField() async {
    final Size canvasSize = Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height - 150);
    final messenger = ScaffoldMessenger.of(context);

    final userLocation = await _pestMapService.getUserFieldLocation();
    final lat = (userLocation['latitude'] as num?)?.toDouble() ?? 7.7818;
    final lng = (userLocation['longitude'] as num?)?.toDouble() ?? 122.5855;

    final normalizedX = (lng - _minLng) / (_maxLng - _minLng);
    final normalizedY = 1.0 - ((lat - _minLat) / (_maxLat - _minLat));

    final baseDx = normalizedX * canvasSize.width;
    final baseDy = normalizedY * canvasSize.height;

    final centerX = canvasSize.width / 2;
    final centerY = canvasSize.height / 2;

    if (!mounted) return;

    setState(() {
      _zoomLevel = 1.8;
      _mapOffset = Offset(centerX - baseDx, centerY - baseDy);
    });

    messenger.showSnackBar(
      SnackBar(
        content: Text('Centered on ${userLocation['fieldName']} (${userLocation['locationName']})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Show Detail Sheet when Pin Tapped ─────────────────────────────────────
  void _showReportDetails(PestReport report) {
    final color = AppTheme.severityColor(report.severity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(_getPestIconData(report.pestType), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              report.fieldName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (report.isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('My Field',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        Text(report.locationName,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reported Pest / Condition:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  SeverityBadge(severity: report.severity, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                report.pestType,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _detailStat('Farmer', report.farmerName, Icons.person_outline_rounded),
                  _detailStat('Affected Area', report.affectedArea, Icons.square_foot_rounded),
                  _detailStat('Date Reported', '${report.timestamp.month}/${report.timestamp.day}/${report.timestamp.year}', Icons.calendar_today_rounded),
                ],
              ),
              const SizedBox(height: 14),

              if (report.notes.isNotEmpty) ...[
                const Text('Observed Symptoms & Notes:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    report.notes,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.3),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Action / Advice Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety_rounded, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getRecommendationForPest(report.pestType),
                        style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
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
  }

  Widget _detailStat(String label, String val, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(height: 2),
          Text(val, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _getRecommendationForPest(String pest) {
    if (pest.contains('Stem Borer')) {
      return 'Action: Release Trichogramma wasps or apply bio-pesticides during egg peak in Zamboanga Sibugay.';
    } else if (pest.contains('Blast')) {
      return 'Action: Avoid excessive Nitrogen fertilizer. Maintain 2-5cm water depth in fields.';
    } else if (pest.contains('Planthopper')) {
      return 'Action: Drain field water for 2-3 days to break lifecycle. Encourage spider predators.';
    } else if (pest.contains('Bacterial')) {
      return 'Action: Use resistant varieties and keep field drainage clean to avoid stagnant contamination.';
    } else if (pest.contains('Snail')) {
      return 'Action: Place bamboo stakes for egg deposition and herd ducks in rice fields post-harvest.';
    }
    return 'Action: Conduct routine field scouting every 3-4 days to prevent early pest flare-ups.';
  }

  // ── Add Pest Report Modal Sheet ───────────────────────────────────────────
  void _showAddReportModal() async {
    final userLoc = await _pestMapService.getUserFieldLocation();

    final fieldNameCtrl = TextEditingController(text: userLoc['fieldName'] as String? ?? '');
    final locationNameCtrl = TextEditingController(text: userLoc['locationName'] as String? ?? '');
    final areaCtrl = TextEditingController(text: '1.0 Hectare');
    final notesCtrl = TextEditingController();

    String selectedPest = PestMapService.pestDiseaseOptions.first;
    String selectedSeverity = 'Yellow Alert';

    double lat = (userLoc['latitude'] as num?)?.toDouble() ?? 7.7818;
    double lng = (userLoc['longitude'] as num?)?.toDouble() ?? 122.5855;

    bool submitting = false;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_location_alt_rounded, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('Report Outbreak in Sibugay',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Input your Zamboanga Sibugay rice field location and pest experience to alert nearby farmers.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 16),

                    // Field Name
                    TextFormField(
                      controller: fieldNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Rice Field Name',
                        hintText: 'e.g. Ipil Central Farm',
                        prefixIcon: Icon(Icons.grass_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Location Preset Dropdown for Zamboanga Sibugay
                    DropdownButtonFormField<String>(
                      value: PestMapService.presetLocations.any((p) => p['name'] == locationNameCtrl.text)
                          ? locationNameCtrl.text
                          : PestMapService.presetLocations.first['name'] as String,
                      decoration: const InputDecoration(
                        labelText: 'Municipality in Zamboanga Sibugay',
                        prefixIcon: Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: PestMapService.presetLocations.map((loc) {
                        return DropdownMenuItem<String>(
                          value: loc['name'] as String,
                          child: Text(
                            loc['name'] as String,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final match = PestMapService.presetLocations.firstWhere((element) => element['name'] == val);
                          setModalState(() {
                            locationNameCtrl.text = val;
                            lat = match['lat'] as double;
                            lng = match['lng'] as double;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Pest / Disease Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedPest,
                      decoration: const InputDecoration(
                        labelText: 'Experienced Pest / Disease',
                        prefixIcon: Icon(Icons.bug_report_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: PestMapService.pestDiseaseOptions.map((pest) {
                        return DropdownMenuItem<String>(
                          value: pest,
                          child: Text(pest, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedPest = val;
                            if (val == 'Healthy Field (No Pest)') {
                              selectedSeverity = 'None';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Severity Selector Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSeverity,
                      decoration: const InputDecoration(
                        labelText: 'Severity Level',
                        prefixIcon: Icon(Icons.warning_rounded),
                        border: OutlineInputBorder(),
                      ),
                      items: ['None', 'Yellow Alert', 'Orange Alert', 'Red Alert'].map((sev) {
                        return DropdownMenuItem<String>(
                          value: sev,
                          child: Text(
                            sev == 'None' ? 'None (Healthy Field)' : sev,
                            style: TextStyle(
                              color: AppTheme.severityColor(sev),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedSeverity = val);
                      },
                    ),
                      const SizedBox(height: 12),

                      // Affected Area & Notes
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: areaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Affected Area',
                                hintText: 'e.g. 1.5 Hectares',
                                prefixIcon: Icon(Icons.square_foot_rounded),
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Symptoms & Observations',
                          hintText: 'e.g. Yellowing leaves, stem deadhearts spotted in Ipil...',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(context);
                          setModalState(() => submitting = true);
                          try {
                            await _pestMapService.addPestReport(
                              fieldName: fieldNameCtrl.text,
                              locationName: locationNameCtrl.text,
                              latitude: lat,
                              longitude: lng,
                              pestType: selectedPest,
                              severity: selectedSeverity,
                              affectedArea: areaCtrl.text,
                              notes: notesCtrl.text,
                            );

                            if (mounted) {
                              nav.pop();
                              _centerOnMyField();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Pest report added to Zamboanga Sibugay map!'),
                                  backgroundColor: AppTheme.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => submitting = false);
                          }
                        },
                        child: submitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Publish Report on Sibugay Map', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

// ── Satellite Map Custom Painter matching Zamboanga Sibugay Image ───────────

class _ZamboangaSibugaySatellitePainter extends CustomPainter {
  final double zoom;
  final Offset offset;

  _ZamboangaSibugaySatellitePainter({required this.zoom, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep Ocean & Sibuguey Bay Dark Water Background
    final waterPaint = Paint()..color = const Color(0xFF0F2B48);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), waterPaint);

    // 2. Satellite Dark Green Terrain Landmass
    final landPaint = Paint()
      ..color = const Color(0xFF1B4D20)
      ..style = PaintingStyle.fill;

    // Red/Pink Dashed Boundary Line matching user image
    final boundaryPaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    // Highway Route AH26 line
    final highwayPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Label Text Styles
    const townTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.bold,
      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
    );

    const bayTextStyle = TextStyle(
      color: Color(0xFF90CAF9),
      fontSize: 12,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w600,
      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
    );

    // ── Zamboanga Sibugay Horseshoe Mainland Contour ───────────────────────
    final Path mainland = Path();
    mainland.moveTo(size.width * 0.12 * zoom + offset.dx, size.height * 0.72 * zoom + offset.dy); // Tungawan
    mainland.lineTo(size.width * 0.28 * zoom + offset.dx, size.height * 0.42 * zoom + offset.dy); // Roseller Lim
    mainland.lineTo(size.width * 0.40 * zoom + offset.dx, size.height * 0.22 * zoom + offset.dy); // Titay
    mainland.lineTo(size.width * 0.46 * zoom + offset.dx, size.height * 0.28 * zoom + offset.dy); // Ipil
    mainland.lineTo(size.width * 0.58 * zoom + offset.dx, size.height * 0.20 * zoom + offset.dy); // Naga
    mainland.lineTo(size.width * 0.72 * zoom + offset.dx, size.height * 0.20 * zoom + offset.dy); // Kabasalan
    mainland.lineTo(size.width * 0.88 * zoom + offset.dx, size.height * 0.28 * zoom + offset.dy); // Buug
    mainland.lineTo(size.width * 0.82 * zoom + offset.dx, size.height * 0.42 * zoom + offset.dy); // Diplahan
    mainland.lineTo(size.width * 0.78 * zoom + offset.dx, size.height * 0.50 * zoom + offset.dy); // Imelda
    mainland.lineTo(size.width * 0.84 * zoom + offset.dx, size.height * 0.58 * zoom + offset.dy); // Malangas
    mainland.lineTo(size.width * 0.75 * zoom + offset.dx, size.height * 0.65 * zoom + offset.dy); // Alicia
    mainland.lineTo(size.width * 0.68 * zoom + offset.dx, size.height * 0.58 * zoom + offset.dy); // Payao
    mainland.lineTo(size.width * 0.72 * zoom + offset.dx, size.height * 0.40 * zoom + offset.dy); // Siay
    mainland.lineTo(size.width * 0.50 * zoom + offset.dx, size.height * 0.38 * zoom + offset.dy); // Sibuguey Bay Coast (Ipil)
    mainland.lineTo(size.width * 0.35 * zoom + offset.dx, size.height * 0.50 * zoom + offset.dy); // R.T. Lim Bay
    mainland.lineTo(size.width * 0.22 * zoom + offset.dx, size.height * 0.68 * zoom + offset.dy); // Tungawan Coast
    mainland.close();

    canvas.drawPath(mainland, landPaint);
    canvas.drawPath(mainland, boundaryPaint);

    // ── Olutanga Island (Mabuhay / Talusan) Contour ──────────────────────────
    final Path olutanga = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.72 * zoom + offset.dx, size.height * 0.82 * zoom + offset.dy),
        width: 85 * zoom,
        height: 70 * zoom,
      ));
    canvas.drawPath(olutanga, landPaint);
    canvas.drawPath(olutanga, boundaryPaint);

    // Buluan Island
    final Path buluanIsland = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(size.width * 0.38 * zoom + offset.dx, size.height * 0.55 * zoom + offset.dy),
        width: 30 * zoom,
        height: 22 * zoom,
      ));
    canvas.drawPath(buluanIsland, landPaint);
    canvas.drawPath(buluanIsland, boundaryPaint);

    // ── Highway Route AH26 Line ──────────────────────────────────────────────
    final Path highwayAH26 = Path();
    highwayAH26.moveTo(size.width * 0.12 * zoom + offset.dx, size.height * 0.72 * zoom + offset.dy); // Tungawan
    highwayAH26.lineTo(size.width * 0.28 * zoom + offset.dx, size.height * 0.42 * zoom + offset.dy); // R.T. Lim
    highwayAH26.lineTo(size.width * 0.46 * zoom + offset.dx, size.height * 0.28 * zoom + offset.dy); // Ipil
    highwayAH26.lineTo(size.width * 0.72 * zoom + offset.dx, size.height * 0.20 * zoom + offset.dy); // Kabasalan
    highwayAH26.lineTo(size.width * 0.88 * zoom + offset.dx, size.height * 0.28 * zoom + offset.dy); // Buug
    canvas.drawPath(highwayAH26, highwayPaint);

    // ── Town Labels Matching Image Layout Exact Position ─────────────────────
    _drawText(canvas, 'Tungawan', Offset(size.width * 0.12 * zoom + offset.dx, size.height * 0.72 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Roseller Lim', Offset(size.width * 0.28 * zoom + offset.dx, size.height * 0.42 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Buluan Island', Offset(size.width * 0.32 * zoom + offset.dx, size.height * 0.56 * zoom + offset.dy), const TextStyle(color: Colors.white70, fontSize: 9.5));
    _drawText(canvas, 'Titay', Offset(size.width * 0.40 * zoom + offset.dx, size.height * 0.20 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Ipil', Offset(size.width * 0.44 * zoom + offset.dx, size.height * 0.28 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Naga', Offset(size.width * 0.56 * zoom + offset.dx, size.height * 0.18 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Kabasalan', Offset(size.width * 0.68 * zoom + offset.dx, size.height * 0.18 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Siay', Offset(size.width * 0.72 * zoom + offset.dx, size.height * 0.36 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Diplahan', Offset(size.width * 0.80 * zoom + offset.dx, size.height * 0.38 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Imelda', Offset(size.width * 0.78 * zoom + offset.dx, size.height * 0.48 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Buug', Offset(size.width * 0.88 * zoom + offset.dx, size.height * 0.26 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Payao', Offset(size.width * 0.66 * zoom + offset.dx, size.height * 0.58 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Alicia', Offset(size.width * 0.76 * zoom + offset.dx, size.height * 0.62 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Malangas', Offset(size.width * 0.82 * zoom + offset.dx, size.height * 0.56 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Olutanga', Offset(size.width * 0.66 * zoom + offset.dx, size.height * 0.82 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Mabuhay', Offset(size.width * 0.74 * zoom + offset.dx, size.height * 0.78 * zoom + offset.dy), townTextStyle);
    _drawText(canvas, 'Talusan', Offset(size.width * 0.76 * zoom + offset.dx, size.height * 0.86 * zoom + offset.dy), townTextStyle);

    // Center Sibuguey Bay Label
    _drawText(canvas, 'Sibuguey Bay', Offset(size.width * 0.48 * zoom + offset.dx, size.height * 0.50 * zoom + offset.dy), bayTextStyle);
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(offset.dx - (painter.width / 2), offset.dy - (painter.height / 2)));
  }

  @override
  bool shouldRepaint(covariant _ZamboangaSibugaySatellitePainter oldDelegate) {
    return oldDelegate.zoom != zoom || oldDelegate.offset != offset;
  }
}
