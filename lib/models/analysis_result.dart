

class AnalysisResult {
  final int?    id;
  final String  filename;
  final String  originalName;
  final String  status;
  final double  confidence;
  final String  severity;
  final String  recommendation;
  final int      detections;
  final String  timestamp;

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
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id:             json['id'] as int?,
      filename:       (json['filename'] ?? '') as String,
      originalName:   (json['original_name'] ?? '') as String,
      status:         (json['status'] ?? 'Unknown') as String,
      confidence:     ((json['confidence'] ?? 0.0) as num).toDouble(),
      severity:       (json['severity'] ?? 'None') as String,
      recommendation: (json['recommendation'] ?? '') as String,
      detections:     (json['detections'] ?? 0) as int,

      timestamp:      (json['analysis_date'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()) as String,
    );
  }

  bool get isHealthy => status == 'Healthy';


  String get severityColorHex {
    switch (severity) {
      case 'Yellow Alert': return '#FFC107';
      case 'Orange Alert': return '#FF9800';
      case 'Red Alert':    return '#F44336';
      default:             return '#4CAF50';
    }
  }
}