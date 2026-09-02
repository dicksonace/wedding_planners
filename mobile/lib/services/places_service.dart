import 'dart:async';

import 'package:dio/dio.dart';

import '../data/ghana_regions.dart';
import '../models/place_suggestion.dart';

/// Ghana-only venue search (OpenStreetMap Nominatim) + local region list.
class PlacesService {
  PlacesService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  Timer? _venueDebounce;
  int _venueRequestId = 0;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org/search';

  /// Search venues, cities, and addresses in Ghana only.
  Future<List<PlaceSuggestion>> searchGhanaVenues(String query, {int limit = 8}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final completer = Completer<List<PlaceSuggestion>>();
    _venueDebounce?.cancel();
    final requestId = ++_venueRequestId;

    _venueDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final results = await _searchNominatimGhana(trimmed, limit: limit);
        if (requestId == _venueRequestId && !completer.isCompleted) {
          completer.complete(results);
        }
      } catch (_) {
        if (requestId == _venueRequestId && !completer.isCompleted) {
          completer.complete([]);
        }
      }
    });

    return completer.future;
  }

  Future<List<PlaceSuggestion>> _searchNominatimGhana(String query, {required int limit}) async {
    final response = await _dio.get<List<dynamic>>(
      _nominatimBase,
      queryParameters: {
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'countrycodes': 'gh',
        'limit': limit,
      },
      options: Options(
        headers: {'User-Agent': 'WedPlanGhana/2.0 (wedding planning app; contact@marriageplan.site)'},
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    final items = response.data ?? [];
    return items
        .map((item) => _fromNominatim(item as Map<String, dynamic>))
        .whereType<PlaceSuggestion>()
        .toList();
  }

  PlaceSuggestion? _fromNominatim(Map<String, dynamic> item) {
    final displayName = (item['display_name'] as String?)?.trim();
    if (displayName == null || displayName.isEmpty) return null;

    final address = item['address'] as Map<String, dynamic>? ?? {};
    final name = (address['amenity'] as String?) ??
        (address['building'] as String?) ??
        (address['tourism'] as String?) ??
        (address['name'] as String?) ??
        (address['road'] as String?) ??
        (address['suburb'] as String?) ??
        (address['city'] as String?) ??
        (address['town'] as String?) ??
        (address['village'] as String?);

    final state = (address['state'] as String?) ?? (address['region'] as String?);
    final region = GhanaRegions.normalize(state);
    final city = (address['city'] as String?) ?? (address['town'] as String?) ?? (address['village'] as String?);

    final label = name?.trim().isNotEmpty == true ? name!.trim() : displayName.split(',').first.trim();

    return PlaceSuggestion(
      label: label,
      displayName: displayName,
      region: region ?? GhanaRegions.normalize(city),
      country: 'Ghana',
      latitude: double.tryParse(item['lat']?.toString() ?? ''),
      longitude: double.tryParse(item['lon']?.toString() ?? ''),
      source: item['type'] as String? ?? item['class'] as String? ?? 'place',
    );
  }

  void dispose() {
    _venueDebounce?.cancel();
  }
}
