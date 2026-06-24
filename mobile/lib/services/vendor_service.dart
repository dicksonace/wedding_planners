import 'package:wedplan_ghana/services/api_client.dart';

class VendorService {
  VendorService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> dashboard() async {
    return _client.get('/vendor/dashboard');
  }

  Future<Map<String, dynamic>> respondToRequest(
    int requestId,
    String status, {
    String? responseMessage,
  }) async {
    return _client.patch('/vendor-requests/$requestId/respond', {
      'status': status,
      if (responseMessage != null) 'response_message': responseMessage,
    });
  }
}
