// lib/models/pest_info.dart
//
// Data model for a single entry in the Rice Pest & Disease Library.
// This is static reference/educational data, separate from AnalysisResult
// (which represents a live scan result).

enum PestType { pest, disease }

class PestInfo {
  final String id;
  final String name;            // English common name
  final String localName;       // Filipino / regional common name
  final String scientificName;  // Causal organism / species
  final PestType type;
  final String description;     // What it is, how it looks/behaves
  final String cause;           // How it's obtained / what causes it, how it spreads
  final String symptoms;        // Signs to look for on the plant
  final String prevention;      // Prevention & safety measures
  final List<String> images;    // Asset paths, 0 to 2 photos
  final String? imageCredit;    // Optional photo credit shown under the photos

  const PestInfo({
    required this.id,
    required this.name,
    required this.localName,
    required this.scientificName,
    required this.type,
    required this.description,
    required this.cause,
    required this.symptoms,
    required this.prevention,
    this.images = const [],
    this.imageCredit,
  });

  bool get isPest => type == PestType.pest;
  bool get isDisease => type == PestType.disease;
}