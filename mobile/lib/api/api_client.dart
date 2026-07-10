import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final data = error.response?.data;
        var message = 'Something went wrong. Please try again.';
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is Map && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final first = errors.values.first;
          message = first is List ? first.first.toString() : first.toString();
        }
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          message: message,
        ));
      },
    ));
  }

  late final Dio _dio;

  Future<String?> _readToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(ApiConfig.tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ApiConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConfig.tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _readToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get(path, queryParameters: query);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, dynamic>? query}) async {
    final data = await get(path, query: query);
    final items = data['data'];
    if (items is List) {
      return items.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.post(path, data: body);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    try {
      final response = await _dio.put(path, data: body);
      return _asMap(response.data);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiException(e.message ?? 'Request failed', statusCode: e.response?.statusCode);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }
}
