import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Live Hostinger API. Set to false only when testing a local Laravel server.
  static const bool useLiveApi = true;
  static const String liveHost = 'https://marriageplan.site';

  static String get baseUrl => '$assetBaseUrl/api';

  static const tokenKey = 'auth_token';

  static String get assetBaseUrl {
    if (useLiveApi) return liveHost;
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final clean = path.startsWith('/') ? path : '/storage/$path';
    return '$assetBaseUrl$clean'.replaceAll('/storage/storage/', '/storage/');
  }
}
