import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/user.dart';

class AppStore extends ChangeNotifier {
  AppStore({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  AppUser? _user;
  bool _loading = false;
  bool _initialized = false;
  String? _error;

  Map<String, dynamic>? coupleDashboard;
  Map<String, dynamic>? vendorDashboard;
  List<Map<String, dynamic>> vendors = [];
  List<String> vendorCategories = [];
  bool vendorsLoading = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String? get error => _error;

  Future<void> init() async {
    if (_initialized) return;
    if (await _api.hasToken()) {
      try {
        final data = await _api.get('/profile');
        _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        await refreshDashboard();
      } catch (_) {
        await _api.clearToken();
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _api.post('/login', body: {
        'email': email,
        'password': password,
      });
      await _api.saveToken(data['token'] as String);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await refreshDashboard();
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Returns the registered email when verification is required (no token issued).
  Future<String> register(Map<String, dynamic> payload) async {
    _setLoading(true);
    try {
      final data = await _api.post('/register', body: payload);
      _error = null;
      return data['email'] as String? ?? payload['email'] as String;
    } on ApiException catch (e) {
      _error = e.message;
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    await _api.post('/email/resend', body: {'email': email});
  }

  Future<void> logout() async {
    try {
      await _api.post('/logout');
    } catch (_) {}
    await _api.clearToken();
    _user = null;
    coupleDashboard = null;
    vendorDashboard = null;
    vendors = [];
    notifyListeners();
  }

  Future<void> refreshDashboard() async {
    if (_user == null) return;
    if (_user!.isCouple) {
      final data = await _api.get('/dashboard');
      coupleDashboard = data['data'] as Map<String, dynamic>?;
    } else if (_user!.isVendor) {
      final data = await _api.get('/vendor/dashboard');
      vendorDashboard = data['data'] as Map<String, dynamic>?;
    }
    notifyListeners();
  }

  Future<void> fetchVendorCategories() async {
    final data = await _api.get('/vendors/categories');
    final list = data['data'];
    if (list is List) {
      vendorCategories = list.map((e) => e.toString()).toList();
      notifyListeners();
    }
  }

  Future<void> searchVendors({String? search, String? category, String? location}) async {
    vendorsLoading = true;
    notifyListeners();
    try {
      final query = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
      if (category != null && category.isNotEmpty) query['category'] = category;
      if (location != null && location.trim().isNotEmpty) query['location'] = location.trim();
      vendors = await _api.getList('/vendors', query: query.isEmpty ? null : query);
    } finally {
      vendorsLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
