class SpeciesLabel {
  final int aiKey;
  final String commonName;
  final String scientificName;
  final String familyName;
  final String speciesType; // 'ENDEMIC' atau 'NON_ENDEMIC'
  final String shortSummary;

  const SpeciesLabel({
    required this.aiKey,
    required this.commonName,
    required this.scientificName,
    required this.familyName,
    required this.speciesType,
    required this.shortSummary,
  });

  bool get isEndemic => speciesType.toUpperCase() == 'ENDEMIC';

  factory SpeciesLabel.fromJson(Map<String, dynamic> json) {
    return SpeciesLabel(
      aiKey: json['ai_key'] as int,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String,
      familyName: json['family_name'] as String,
      speciesType: json['species_type'] as String,
      shortSummary: json['short_summary'] as String,
    );
  }
}