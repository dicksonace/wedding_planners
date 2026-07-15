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
  List<Map<String, dynamic>> guests = [];
  bool guestsLoading = false;
  List<Map<String, dynamic>> budgetItems = [];
  Map<String, dynamic>? budgetSummary;
  bool budgetLoading = false;
  List<Map<String, dynamic>> tasks = [];
  bool tasksLoading = false;
  List<Map<String, dynamic>> vendorRequests = [];
  bool vendorRequestsLoading = false;
  List<Map<String, dynamic>> weddingMedia = [];
  bool weddingMediaLoading = false;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _loading;
  bool get isInitialized => _initialized;
  String? get error => _error;
  bool get hasPlan => coupleDashboard?['has_plan'] == true;

  int? get activePlanId {
    final plan = coupleDashboard?['plan'];
    if (plan is Map<String, dynamic>) return plan['id'] as int?;
    return null;
  }

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
    guests = [];
    budgetItems = [];
    budgetSummary = null;
    tasks = [];
    vendorRequests = [];
    weddingMedia = [];
    notifyListeners();
  }

  Future<void> createWeddingPlan(Map<String, dynamic> payload) async {
    await _api.post('/wedding-plans', body: payload);
    await refreshDashboard();
  }

  Future<void> fetchGuests() async {
    final planId = activePlanId;
    if (planId == null) {
      guests = [];
      notifyListeners();
      return;
    }

    guestsLoading = true;
    notifyListeners();
    try {
      guests = await _api.getList('/wedding-plans/$planId/guests');
    } finally {
      guestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGuest(Map<String, dynamic> payload) async {
    final planId = activePlanId;
    if (planId == null) {
      throw ApiException('Create a wedding plan before adding guests.');
    }
    await _api.post('/wedding-plans/$planId/guests', body: payload);
    await fetchGuests();
    await refreshDashboard();
  }

  Future<void> deleteGuest(int guestId) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.delete('/wedding-plans/$planId/guests/$guestId');
    await fetchGuests();
    await refreshDashboard();
  }

  Future<void> fetchBudgetItems() async {
    final planId = activePlanId;
    if (planId == null) {
      budgetItems = [];
      budgetSummary = null;
      notifyListeners();
      return;
    }

    budgetLoading = true;
    notifyListeners();
    try {
      final data = await _api.get('/wedding-plans/$planId/budget-items');
      final items = data['data'];
      if (items is List) {
        budgetItems = items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        budgetItems = [];
      }
      final summary = data['summary'];
      budgetSummary = summary is Map ? Map<String, dynamic>.from(summary) : null;
    } finally {
      budgetLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBudgetItem(Map<String, dynamic> payload) async {
    final planId = activePlanId;
    if (planId == null) {
      throw ApiException('Create a wedding plan before adding budget items.');
    }
    await _api.post('/wedding-plans/$planId/budget-items', body: payload);
    await fetchBudgetItems();
    await refreshDashboard();
  }

  Future<void> updateBudgetItem(int itemId, Map<String, dynamic> payload) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.put('/wedding-plans/$planId/budget-items/$itemId', body: payload);
    await fetchBudgetItems();
    await refreshDashboard();
  }

  Future<void> deleteBudgetItem(int itemId) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.delete('/wedding-plans/$planId/budget-items/$itemId');
    await fetchBudgetItems();
    await refreshDashboard();
  }

  Future<void> fetchTasks() async {
    final planId = activePlanId;
    if (planId == null) {
      tasks = [];
      notifyListeners();
      return;
    }

    tasksLoading = true;
    notifyListeners();
    try {
      tasks = await _api.getList('/wedding-plans/$planId/tasks');
    } finally {
      tasksLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Map<String, dynamic> payload) async {
    final planId = activePlanId;
    if (planId == null) {
      throw ApiException('Create a wedding plan before adding tasks.');
    }
    await _api.post('/wedding-plans/$planId/tasks', body: payload);
    await fetchTasks();
    await refreshDashboard();
  }

  Future<void> updateTask(int taskId, Map<String, dynamic> payload) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.put('/wedding-plans/$planId/tasks/$taskId', body: payload);
    await fetchTasks();
    await refreshDashboard();
  }

  Future<void> deleteTask(int taskId) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.delete('/wedding-plans/$planId/tasks/$taskId');
    await fetchTasks();
    await refreshDashboard();
  }

  Future<Map<String, dynamic>> fetchVendor(int vendorId) async {
    final data = await _api.get('/vendors/$vendorId');
    final vendor = data['data'];
    if (vendor is Map<String, dynamic>) return vendor;
    if (vendor is Map) return Map<String, dynamic>.from(vendor);
    return {};
  }

  Future<void> fetchVendorRequests() async {
    final planId = activePlanId;
    if (planId == null) {
      vendorRequests = [];
      notifyListeners();
      return;
    }

    vendorRequestsLoading = true;
    notifyListeners();
    try {
      vendorRequests = await _api.getList('/wedding-plans/$planId/vendor-requests');
    } finally {
      vendorRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVendorRequest({required int vendorId, String? message}) async {
    final planId = activePlanId;
    if (planId == null) {
      throw ApiException('Create a wedding plan before contacting vendors.');
    }
    await _api.post('/wedding-plans/$planId/vendor-requests', body: {
      'vendor_id': vendorId,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
    });
    await fetchVendorRequests();
    await refreshDashboard();
  }

  Future<void> cancelVendorRequest(int requestId) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.delete('/wedding-plans/$planId/vendor-requests/$requestId');
    await fetchVendorRequests();
    await refreshDashboard();
  }

  Future<void> respondToVendorRequest(int requestId, {required String status, String? responseMessage}) async {
    await _api.patch('/vendor-requests/$requestId/respond', body: {
      'status': status,
      if (responseMessage != null && responseMessage.trim().isNotEmpty) 'response_message': responseMessage.trim(),
    });
    await refreshDashboard();
  }

  Future<void> updateProfile(Map<String, dynamic> payload) async {
    final data = await _api.put('/profile', body: payload);
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      _user = AppUser.fromJson(user);
      notifyListeners();
    }
  }

  Future<void> fetchWeddingMedia({String? type}) async {
    final planId = activePlanId;
    if (planId == null) {
      weddingMedia = [];
      notifyListeners();
      return;
    }

    weddingMediaLoading = true;
    notifyListeners();
    try {
      weddingMedia = await _api.getList(
        '/wedding-plans/$planId/media',
        query: type == null ? null : {'type': type},
      );
    } finally {
      weddingMediaLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadWeddingMedia({
    required String filePath,
    required String type,
    String? title,
  }) async {
    final planId = activePlanId;
    if (planId == null) {
      throw ApiException('Create a wedding plan before uploading images.');
    }
    await _api.uploadMultipart(
      '/wedding-plans/$planId/media',
      filePath: filePath,
      fileField: 'file',
      fields: {
        'type': type,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      },
    );
    await fetchWeddingMedia();
  }

  Future<void> deleteWeddingMedia(int mediaId) async {
    final planId = activePlanId;
    if (planId == null) return;
    await _api.delete('/wedding-plans/$planId/media/$mediaId');
    await fetchWeddingMedia();
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
