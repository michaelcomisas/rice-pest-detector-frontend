// lib/models/analysis_result.dart

import 'package:flutter/material.dart';

class AnalysisResult {
  final int? id;
  final String filename;
  final String originalName;
  final String status;
  final double confidence;
  final String severity;
  final String recommendation;
  final int detections;
  final String timestamp;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const AnalysisResult({
    this.id,
    required this.filename,
    required this.originalName,
    required this.status,
    required this.confidence,
    required this.severity,
    required this.recommendation,
    required this.detections,
    required this.timestamp,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] as int?,
      filename: (json['filename'] ?? '') as String,
      originalName: (json['original_name'] ?? '') as String,
      status: (json['status'] ?? 'Unknown') as String,
      confidence: ((json['confidence'] ?? 0.0) as num).toDouble(),
      severity: (json['severity'] ?? 'None') as String,
      recommendation: (json['recommendation'] ?? '') as String,
      detections: (json['detections'] ?? 0) as int,
      timestamp: (json['analysis_date'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()) as String,
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'original_name': originalName,
        'status': status,
        'confidence': confidence,
        'severity': severity,
        'recommendation': recommendation,
        'detections': detections,
        'timestamp': timestamp,
        'location_name': locationName,
        'latitude': latitude,
        'longitude': longitude,
      };

  AnalysisResult copyWithLocation({
    String? locationName,
    double? latitude,
    double? longitude,
  }) {
    return AnalysisResult(
      id: id,
      filename: filename,
      originalName: originalName,
      status: status,
      confidence: confidence,
      severity: severity,
      recommendation: recommendation,
      detections: detections,
      timestamp: timestamp,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  bool get isHealthy => status == 'Healthy' || severity == 'None';

  // ── 1. Color Coding Detection Properties ─────────────────────────────────
  String get severityColorHex {
    switch (severity) {
      case 'Yellow Alert':
        return '#FFC107';
      case 'Orange Alert':
        return '#FF9800';
      case 'Red Alert':
        return '#F44336';
      default:
        return '#4CAF50';
    }
  }

  Color get colorCode {
    switch (severity) {
      case 'Yellow Alert':
        return const Color(0xFFF57F17); // Dark Amber / Yellow
      case 'Orange Alert':
        return const Color(0xFFE65100); // Deep Orange
      case 'Red Alert':
        return const Color(0xFFC62828); // Strong Crimson Red
      default:
        return const Color(0xFF2E7D32); // Deep Forest Green
    }
  }

  String get colorCodingLabel {
    switch (severity) {
      case 'Yellow Alert':
        return 'YELLOW CODE: Mild Threat / Early Infestation Detected';
      case 'Orange Alert':
        return 'ORANGE CODE: Moderate Threat / Action Required Soon';
      case 'Red Alert':
        return 'RED CODE: Severe Threat / Immediate Outbreak Intervention!';
      default:
        return 'GREEN CODE: Safe & Healthy Crop / Normal Condition';
    }
  }

  // ── 2. Prevention & Treatment Tips (Based on analyzed disease/pest) ─────
  List<String> get preventionTips {
    final s = status.toLowerCase();
    final rec = recommendation.toLowerCase();

    if (s.contains('stem borer') || rec.contains('stem borer')) {
      return [
        'Practice synchronized planting within a 2-week window across neighboring farms.',
        'Plow stubbles immediately after harvest to destroy diapausing larvae.',
        'Conserve natural egg parasitoids (Trichogramma wasps).',
        'Use light traps during egg-laying peak periods (3-5 days after full moon).',
        'Maintain balanced nitrogen fertilizer application; avoid over-fertilizing.',
      ];
    } else if (s.contains('blast') || rec.contains('blast')) {
      return [
        'Avoid excessive Nitrogen fertilizer; split application into 3-4 smaller doses.',
        'Keep water level at 2-5cm depth continuously to suppress blast spore infection.',
        'Use certified blast-resistant seed varieties recommended for your region.',
        'Ensure proper plant spacing during transplanting to reduce canopy leaf wetness.',
        'Apply systemic fungicides early at the first appearance of diamond leaf spots.',
      ];
    } else if (s.contains('planthopper') || s.contains('hopper') || rec.contains('planthopper')) {
      return [
        'Avoid broad-spectrum insecticide sprays to protect natural spider predators.',
        'Drain field water for 2-3 days to disturb brown planthopper nymph colonies.',
        'Use wider row spacing (20cm x 20cm) for better sunlight and canopy aeration.',
        'Monitor plant bases weekly for hopperburn patches and egg masses.',
        'Apply selective insecticides only when population exceeds 10 hoppers per hill.',
      ];
    } else if (s.contains('bacterial') || s.contains('blight') || rec.contains('bacterial')) {
      return [
        'Ensure clean, non-contaminated irrigation water supply.',
        'Avoid clipping leaf tips during seedling transplanting to prevent bacterial entry.',
        'Fallow and dry fields thoroughly between cropping seasons.',
        'Apply copper-based or bactericide treatments at early symptom onset.',
        'Avoid working in wet fields during morning dew to prevent mechanical spread.',
      ];
    } else if (s.contains('sheath') || rec.contains('sheath')) {
      return [
        'Clear weeds from bunds and canals that serve as alternate hosts.',
        'Reduce seeding rate or widen transplanting distance to allow airflow.',
        'Remove infected plant sheaths after harvest and deeply plow stubbles.',
        'Apply validamycin or recommended bio-fungicides at early tillering stage.',
      ];
    } else if (s.contains('tungro') || rec.contains('tungro')) {
      return [
        'Rogue out (dig up and destroy) infected stunted plants immediately.',
        'Manage vector Green Leafhoppers using registered selective insecticides.',
        'Plant resistant rice cultivars (e.g. Matatag varieties).',
        'Implement fallow period of at least 30 days between seasons.',
      ];
    } else if (s.contains('snail') || s.contains('kuhol') || rec.contains('snail')) {
      return [
        'Place bamboo stakes along field edges to collect and crush pink egg masses.',
        'Herd ducks in fields before transplanting or 30 days post-transplanting.',
        'Construct shallow micro-canals around field perimeters to trap snails.',
        'Use wire mesh or screens on water inlets to prevent snail entry.',
      ];
    } else {
      // Healthy Crop or Default Prevention Best Practices
      return [
        'Scout rice fields twice weekly, checking leaves, stems, and plant bases.',
        'Apply balanced N-P-K fertilizers according to Leaf Color Chart (LCC).',
        'Maintain clean irrigation ditches and weed-free field boundaries.',
        'Conserve natural beneficial insects (spiders, dragonflies, ladybird beetles).',
        'Use certified high-quality seeds treated against seed-borne pathogens.',
      ];
    }
  }
}
