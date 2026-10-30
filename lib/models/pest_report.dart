// lib/models/pest_report.dart

class PestReport {
  final String id;
  final String farmerName;
  final String mobile;
  final String fieldName;
  final String locationName;
  final double latitude;
  final double longitude;
  final String pestType;
  final String severity; // 'None', 'Yellow Alert', 'Orange Alert', 'Red Alert'
  final String affectedArea;
  final String notes;
  final DateTime timestamp;
  final bool isCurrentUser;

  PestReport({
    required this.id,
    required this.farmerName,
    required this.mobile,
    required this.fieldName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.pestType,
    required this.severity,
    required this.affectedArea,
    required this.notes,
    required this.timestamp,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'farmerName': farmerName,
        'mobile': mobile,
        'fieldName': fieldName,
        'locationName': locationName,
        'latitude': latitude,
        'longitude': longitude,
        'pestType': pestType,
        'severity': severity,
        'affectedArea': affectedArea,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
        'isCurrentUser': isCurrentUser,
      };

  factory PestReport.fromJson(Map<String, dynamic> json) => PestReport(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        farmerName: json['farmerName'] as String? ?? 'Anonymous Farmer',
        mobile: json['mobile'] as String? ?? '',
        fieldName: json['fieldName'] as String? ?? 'Rice Field',
        locationName: json['locationName'] as String? ?? 'Central Luzon',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 15.4827,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 120.9698,
        pestType: json['pestType'] as String? ?? 'Yellow Stem Borer',
        severity: json['severity'] as String? ?? 'Yellow Alert',
        affectedArea: json['affectedArea'] as String? ?? '1.0 Hectare',
        notes: json['notes'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
            : DateTime.now(),
        isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      );
}
