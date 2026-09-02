/// All 16 administrative regions of Ghana.
class GhanaRegions {
  GhanaRegions._();

  static const all = [
    'Greater Accra',
    'Ashanti',
    'Western',
    'Eastern',
    'Central',
    'Northern',
    'Volta',
    'Upper East',
    'Upper West',
    'Bono',
    'Bono East',
    'Ahafo',
    'Western North',
    'Oti',
    'Savannah',
    'North East',
  ];

  /// Match free-text (e.g. from maps) to a known region name.
  static String? normalize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final cleaned = raw.replaceAll(' Region', '').trim().toLowerCase();
    for (final region in all) {
      if (region.toLowerCase() == cleaned || cleaned.contains(region.toLowerCase())) {
        return region;
      }
    }
    return null;
  }

  static List<String> search(String query, {int limit = 8}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all.take(limit).toList();
    return all.where((r) => r.toLowerCase().contains(q)).take(limit).toList();
  }
}
