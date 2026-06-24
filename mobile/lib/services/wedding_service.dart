import 'package:wedplan_ghana/services/api_client.dart';

class WeddingService {
  WeddingService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    return _client.get('/dashboard');
  }

  Future<List<dynamic>> weddingPlans() async {
    final response = await _client.get('/wedding-plans');
    return response['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> createPlan(Map<String, dynamic> payload) async {
    return _client.post('/wedding-plans', payload);
  }

  Future<List<dynamic>> guests(int planId) async {
    final response = await _client.get('/wedding-plans/$planId/guests');
    return response['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> addGuest(int planId, Map<String, dynamic> payload) async {
    return _client.post('/wedding-plans/$planId/guests', payload);
  }

  Future<Map<String, dynamic>> updateGuest(int planId, int guestId, Map<String, dynamic> payload) async {
    return _client.put('/wedding-plans/$planId/guests/$guestId', payload);
  }

  Future<Map<String, dynamic>> sendGuestInvitation(int planId, int guestId) async {
    return _client.post('/wedding-plans/$planId/guests/$guestId/invite', {});
  }

  Future<Map<String, dynamic>> budgetItems(int planId) async {
    return _client.get('/wedding-plans/$planId/budget-items');
  }

  Future<Map<String, dynamic>> addBudgetItem(int planId, Map<String, dynamic> payload) async {
    return _client.post('/wedding-plans/$planId/budget-items', payload);
  }

  Future<Map<String, dynamic>> updateBudgetItem(int planId, int itemId, Map<String, dynamic> payload) async {
    return _client.put('/wedding-plans/$planId/budget-items/$itemId', payload);
  }

  Future<List<dynamic>> tasks(int planId) async {
    final response = await _client.get('/wedding-plans/$planId/tasks');
    return response['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> addTask(int planId, Map<String, dynamic> payload) async {
    return _client.post('/wedding-plans/$planId/tasks', payload);
  }

  Future<List<dynamic>> vendors({String? category, String? search}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (search != null && search.isNotEmpty) query['search'] = search;

    final path = query.isEmpty ? '/vendors' : '/vendors?${Uri(queryParameters: query).query}';
    final response = await _client.get(path);
    return response['data'] as List<dynamic>;
  }

  Future<List<dynamic>> vendorCategories() async {
    final response = await _client.get('/vendors/categories');
    return response['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> requestVendor(int planId, int vendorId, String message) async {
    return _client.post('/wedding-plans/$planId/vendor-requests', {
      'vendor_id': vendorId,
      'message': message,
    });
  }
}
