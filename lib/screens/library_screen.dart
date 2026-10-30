// lib/screens/library_screen.dart
// ─────────────────────────────────
// Educational reference library of common rice pests & diseases.
// Lets farmers browse and search, independent of running a live scan.

import 'package:flutter/material.dart';
import '../models/pest_info.dart';
import '../data/pest_library_data.dart';
import '../utils/app_theme.dart';
import 'pest_info_detail_screen.dart';

enum _LibraryFilter { all, pests, diseases }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';
  _LibraryFilter _filter = _LibraryFilter.all;

  List<PestInfo> get _filteredEntries {
    return pestLibraryData.where((entry) {
      final matchesFilter = switch (_filter) {
        _LibraryFilter.all => true,
        _LibraryFilter.pests => entry.isPest,
        _LibraryFilter.diseases => entry.isDisease,
      };
      if (!matchesFilter) return false;

      if (_query.trim().isEmpty) return true;
      final q = _query.trim().toLowerCase();
      return entry.name.toLowerCase().contains(q) ||
          entry.localName.toLowerCase().contains(q) ||
          entry.scientificName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pest & Disease Library',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppTheme.primaryLight.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterChip('All', _LibraryFilter.all),
                const SizedBox(width: 8),
                _filterChip('Pests', _LibraryFilter.pests),
                const SizedBox(width: 8),
                _filterChip('Diseases', _LibraryFilter.diseases),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      'No matching entries found.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _entryCard(entries[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _LibraryFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.08),
    );
  }

  Widget _entryCard(PestInfo entry) {
    final isPest = entry.isPest;
    return Card(
      elevation: 0,
      color: AppTheme.primaryLight.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.primaryLight.withValues(alpha: 0.25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor:
              (isPest ? Colors.brown : Colors.redAccent).withValues(alpha: 0.15),
          child: Icon(
            isPest ? Icons.bug_report_rounded : Icons.coronavirus_rounded,
            color: isPest ? Colors.brown : Colors.redAccent,
          ),
        ),
        title: Text(entry.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PestInfoDetailScreen(entry: entry),
            ),
          );
        },
      ),
    );
  }
}