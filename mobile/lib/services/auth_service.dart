import 'package:wedplan_ghana/models/user.dart';
import 'package:wedplan_ghana/services/api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<User> login(String email, String password) async {
    final response = await _client.post('/login', {
      'email': email,
      'password': password,
    });

    await _client.saveToken(response['token'] as String);
    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<User> register(Map<String, dynamic> payload) async {
    final response = await _client.post('/register', payload);
    await _client.saveToken(response['token'] as String);
    return User.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<User?> currentUser() async {
    if (_client.token == null) return null;

    try {
      final response = await _client.get('/profile');
      return User.fromJson(response['user'] as Map<String, dynamic>);
    } catch (_) {
      await _client.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _client.post('/logout', {});
    } finally {
      await _client.clearToken();
    }
  }
}
