// lib/services/pest_map_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pest_report.dart';
import 'auth_service.dart';

class PestMapService {
  PestMapService._internal();
  static final PestMapService instance = PestMapService._internal();

  static const _fieldLocationKey = 'user_rice_field_location';
  static const _pestReportsKey = 'user_pest_reports_list';

  final ValueNotifier<int> reportsNotifier = ValueNotifier<int>(0);

  // ── Default Sample Community Reports (Zamboanga Sibugay Municipalities) ──
  final List<PestReport> _sampleCommunityReports = [
    PestReport(
      id: 'pin_sibugay_1',
      farmerName: 'Juan Dela Cruz',
      mobile: '0917****123',
      fieldName: 'Ipil Central Rice Farm',
      locationName: 'Ipil, Zamboanga Sibugay',
      latitude: 7.7818,
      longitude: 122.5855,
      pestType: 'Yellow Stem Borer',
      severity: 'Red Alert',
      affectedArea: '2.5 Hectares',
      notes: 'Observed deadhearts in young tillers across lower Ipil irrigation basin.',
      timestamp: DateTime.now().subtract(const Duration(hours: 14)),
    ),
    PestReport(
      id: 'pin_sibugay_2',
      farmerName: 'Pedro Penduko',
      mobile: '0918****456',
      fieldName: 'Titay Agrarian Field',
      locationName: 'Titay, Zamboanga Sibugay',
      latitude: 7.8425,
      longitude: 122.5480,
      pestType: 'Rice Blast (Magnaporthe oryzae)',
      severity: 'Orange Alert',
      affectedArea: '1.8 Hectares',
      notes: 'Diamond-shaped spindle lesions visible on leaves near Titay river valley.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PestReport(
      id: 'pin_sibugay_3',
      farmerName: 'Maria Santos',
      mobile: '0922****789',
      fieldName: 'Kabasalan Riverbank Rice Plot',
      locationName: 'Kabasalan, Zamboanga Sibugay',
      latitude: 7.8105,
      longitude: 122.7562,
      pestType: 'Brown Planthopper (BPH)',
      severity: 'Red Alert',
      affectedArea: '3.0 Hectares',
      notes: 'Hopperburn patches appearing in lower leaf canopy in Kabasalan.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PestReport(
      id: 'pin_sibugay_4',
      farmerName: 'Ramon Magsaysay',
      mobile: '0915****331',
      fieldName: 'Naga Eco Rice Farm',
      locationName: 'Naga, Zamboanga Sibugay',
      latitude: 7.7825,
      longitude: 122.6841,
      pestType: 'Bacterial Leaf Blight',
      severity: 'Yellow Alert',
      affectedArea: '0.8 Hectare',
      notes: 'Water-soaked yellow wavy leaf margins spotted after heavy downpour.',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
    ),
    PestReport(
      id: 'pin_sibugay_5',
      farmerName: 'Elena Adarna',
      mobile: '0928****992',
      fieldName: 'Diplahan Terraces & Valley',
      locationName: 'Diplahan, Zamboanga Sibugay',
      latitude: 7.6740,
      longitude: 123.0310,
      pestType: 'Rice Tungro Virus',
      severity: 'Orange Alert',
      affectedArea: '1.2 Hectares',
      notes: 'Yellowish-orange leaf discoloration and stunted tiller growth.',
      timestamp: DateTime.now().subtract(const Duration(days: 4)),
    ),
    PestReport(
      id: 'pin_sibugay_6',
      farmerName: 'Kiko Pangilinan',
      mobile: '0919****004',
      fieldName: 'Buug Agritheque Field',
      locationName: 'Buug, Zamboanga Sibugay',
      latitude: 7.7311,
      longitude: 123.0560,
      pestType: 'Healthy Field (No Pest)',
      severity: 'None',
      affectedArea: '2.0 Hectares',
      notes: 'Regular scouting scan completed. Crop canopy green and healthy.',
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PestReport(
      id: 'pin_sibugay_7',
      farmerName: 'Cardo Dalisay',
      mobile: '0939****811',
      fieldName: 'Siay Coastal Rice Basin',
      locationName: 'Siay, Zamboanga Sibugay',
      latitude: 7.7058,
      longitude: 122.8465,
      pestType: 'Golden Apple Snail (Kuhol)',
      severity: 'Orange Alert',
      affectedArea: '1.5 Hectares',
      notes: 'Pink egg clusters on stems. Cut seedlings spotted post-transplant.',
      timestamp: DateTime.now().subtract(const Duration(days: 6)),
    ),
    PestReport(
      id: 'pin_sibugay_8',
      farmerName: 'Manny Pacquiao',
      mobile: '0908****622',
      fieldName: 'Roseller Lim Agrarian Estate',
      locationName: 'Roseller Lim, Zamboanga Sibugay',
      latitude: 7.6890,
      longitude: 122.4485,
      pestType: 'Sheath Blight (Rhizoctonia)',
      severity: 'Yellow Alert',
      affectedArea: '2.2 Hectares',
      notes: 'Greenish-gray sheath lesions observed near water line.',
      timestamp: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  // ── Get User Rice Field Location Settings (Zamboanga Sibugay Default) ────
  Future<Map<String, dynamic>> getUserFieldLocation() async {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) {
      return {
        'fieldName': 'My Rice Field',
        'locationName': 'Ipil, Zamboanga Sibugay',
        'latitude': 7.7818,
        'longitude': 122.5855,
      };
    }
    final prefs = await SharedPreferences.getInstance();
    final key = auth.scopedKey(_fieldLocationKey);
    final raw = prefs.getString(key);
    if (raw == null) {
      return {
        'fieldName': '${auth.displayName ?? 'Farmer'}\'s Rice Field',
        'locationName': 'Ipil, Zamboanga Sibugay',
        'latitude': 7.7818,
        'longitude': 122.5855,
      };
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {
        'fieldName': 'My Rice Field',
        'locationName': 'Ipil, Zamboanga Sibugay',
        'latitude': 7.7818,
        'longitude': 122.5855,
      };
    }
  }

  // ── Save User Rice Field Location Settings ──────────────────────────────
  Future<void> saveUserFieldLocation({
    required String fieldName,
    required String locationName,
    required double latitude,
    required double longitude,
  }) async {
    final auth = AuthService.instance;
    if (!auth.isLoggedIn) return;
    final prefs = await SharedPreferences.getInstance();
    final key = auth.scopedKey(_fieldLocationKey);
    final data = {
      'fieldName': fieldName.trim(),
      'locationName': locationName.trim(),
      'latitude': latitude,
      'longitude': longitude,
    };
    await prefs.setString(key, jsonEncode(data));
    reportsNotifier.value++;
  }

  // ── Save a New Pest / Disease Report ─────────────────────────────────────
  Future<PestReport> addPestReport({
    required String fieldName,
    required String locationName,
    required double latitude,
    required double longitude,
    required String pestType,
    required String severity,
    required String affectedArea,
    required String notes,
  }) async {
    final auth = AuthService.instance;
    final userMobile = auth.currentUser ?? '09000000000';
    final userName = auth.displayName ?? 'CurrentUser';

    final report = PestReport(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      farmerName: userName,
      mobile: userMobile,
      fieldName: fieldName.trim().isEmpty ? 'My Rice Field' : fieldName.trim(),
      locationName: locationName.trim().isEmpty ? 'Ipil, Zamboanga Sibugay' : locationName.trim(),
      latitude: latitude,
      longitude: longitude,
      pestType: pestType,
      severity: severity,
      affectedArea: affectedArea.trim().isEmpty ? '1.0 Hectare' : affectedArea.trim(),
      notes: notes.trim(),
      timestamp: DateTime.now(),
      isCurrentUser: true,
    );

    // Persist user location as default
    await saveUserFieldLocation(
      fieldName: report.fieldName,
      locationName: report.locationName,
      latitude: latitude,
      longitude: longitude,
    );

    // Save report to user's saved list
    final prefs = await SharedPreferences.getInstance();
    final reportsKey = auth.scopedKey(_pestReportsKey);
    final existing = await _loadUserReports(prefs, reportsKey);
    existing.insert(0, report);

    final rawList = existing.map((r) => r.toJson()).toList();
    await prefs.setString(reportsKey, jsonEncode(rawList));

    reportsNotifier.value++;
    return report;
  }

  // ── Get All Map Pins (User + Community) ──────────────────────────────────
  Future<List<PestReport>> getAllMapReports() async {
    final auth = AuthService.instance;
    List<PestReport> userReports = [];

    if (auth.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final reportsKey = auth.scopedKey(_pestReportsKey);
      userReports = await _loadUserReports(prefs, reportsKey);
    }

    final Map<String, PestReport> combined = {};

    for (final sample in _sampleCommunityReports) {
      combined[sample.id] = sample;
    }

    for (final ur in userReports) {
      combined[ur.id] = ur;
    }

    final result = combined.values.toList();
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  Future<List<PestReport>> _loadUserReports(
      SharedPreferences prefs, String key) async {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    try {
      final List parsed = jsonDecode(raw) as List;
      return parsed
          .map((item) => PestReport.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Pre-defined List of Common Rice Pests & Diseases ─────────────────────
  static const List<String> pestDiseaseOptions = [
    'Yellow Stem Borer',
    'Rice Blast (Magnaporthe oryzae)',
    'Brown Planthopper (BPH)',
    'Bacterial Leaf Blight',
    'Rice Tungro Virus',
    'Sheath Blight',
    'Golden Apple Snail (Kuhol)',
    'Green Leafhopper',
    'Rice Bug (Atangya)',
    'Healthy Field (No Pest)',
  ];

  // ── Municipalities of Zamboanga Sibugay Presets ───────────────────────────
  static const List<Map<String, dynamic>> presetLocations = [
    {
      'name': 'Ipil, Zamboanga Sibugay (Capital)',
      'lat': 7.7818,
      'lng': 122.5855,
    },
    {
      'name': 'Titay, Zamboanga Sibugay',
      'lat': 7.8425,
      'lng': 122.5480,
    },
    {
      'name': 'Roseller Lim (R.T. Lim), Zamboanga Sibugay',
      'lat': 7.6890,
      'lng': 122.4485,
    },
    {
      'name': 'Kabasalan, Zamboanga Sibugay',
      'lat': 7.8105,
      'lng': 122.7562,
    },
    {
      'name': 'Naga, Zamboanga Sibugay',
      'lat': 7.7825,
      'lng': 122.6841,
    },
    {
      'name': 'Siay, Zamboanga Sibugay',
      'lat': 7.7058,
      'lng': 122.8465,
    },
    {
      'name': 'Diplahan, Zamboanga Sibugay',
      'lat': 7.6740,
      'lng': 123.0310,
    },
    {
      'name': 'Imelda, Zamboanga Sibugay',
      'lat': 7.6320,
      'lng': 122.9550,
    },
    {
      'name': 'Buug, Zamboanga Sibugay',
      'lat': 7.7311,
      'lng': 123.0560,
    },
    {
      'name': 'Payao, Zamboanga Sibugay',
      'lat': 7.5240,
      'lng': 122.8020,
    },
    {
      'name': 'Alicia, Zamboanga Sibugay',
      'lat': 7.5312,
      'lng': 122.9230,
    },
    {
      'name': 'Malangas, Zamboanga Sibugay',
      'lat': 7.6280,
      'lng': 122.9010,
    },
    {
      'name': 'Tungawan, Zamboanga Sibugay',
      'lat': 7.5458,
      'lng': 122.3620,
    },
    {
      'name': 'Mabuhay, Zamboanga Sibugay (Olutanga)',
      'lat': 7.4120,
      'lng': 122.8450,
    },
    {
      'name': 'Olutanga, Zamboanga Sibugay',
      'lat': 7.3110,
      'lng': 122.8480,
    },
    {
      'name': 'Talusan, Zamboanga Sibugay',
      'lat': 7.3520,
      'lng': 122.8210,
    },
    {
      'name': 'Buluan Island, Zamboanga Sibugay',
      'lat': 7.6520,
      'lng': 122.5120,
    },
  ];
}
