class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.displayName,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
    this.source = 'places',
  });

  final String label;
  final String displayName;
  final String? region;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String source;

  bool get isGhana => country?.toLowerCase() == 'ghana' || country?.toLowerCase() == 'gh';
}
