import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(ApiConstants.tokenKey);
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(ApiConstants.tokenKey);
    return _token;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(ApiConstants.tokenKey, token);
    } else {
      await prefs.remove(ApiConstants.tokenKey);
    }
  }

  Future<void> clearAuth() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.tokenKey);
    await prefs.remove(ApiConstants.userKey);
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      if (queryParams != null && queryParams.isNotEmpty) {
        final stringParams = queryParams.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        )..removeWhere((k, v) => v.isEmpty);
        return uri.replace(queryParameters: stringParams);
      }
      return uri;
    }

    String cleanPath = path.startsWith('/') ? path : '/$path';
    String fullUrl;

    if (cleanPath.startsWith(ApiConstants.apiPrefix)) {
      fullUrl = '${ApiConstants.rootBase}$cleanPath';
    } else if (cleanPath == ApiConstants.root ||
        cleanPath == ApiConstants.health ||
        cleanPath.startsWith(ApiConstants.swaggerDocs) ||
        cleanPath.startsWith(ApiConstants.redocDocs)) {
      fullUrl = '${ApiConstants.rootBase}$cleanPath';
    } else {
      fullUrl = '${ApiConstants.apiBase}$cleanPath';
    }

    final uri = Uri.parse(fullUrl);

    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      )..removeWhere((k, v) => v.isEmpty);
      return uri.replace(queryParameters: stringParams);
    }

    return uri;
  }

  Future<dynamic> request({
    required String method,
    required String path,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final token = await getToken();
    final uri = _buildUri(path, queryParams);

    final reqHeaders = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    http.Response response;
    try {
      final jsonBody = (body != null && body is! String) ? jsonEncode(body) : body;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: reqHeaders);
          break;
        case 'POST':
          response = await http.post(uri, headers: reqHeaders, body: jsonBody);
          break;
        case 'PUT':
          response = await http.put(uri, headers: reqHeaders, body: jsonBody);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: reqHeaders, body: jsonBody);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: reqHeaders, body: jsonBody);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw Exception(
        'Unable to connect to MandiSync backend at ${uri.host}:${uri.port}. Ensure FastAPI is active.',
      );
    }

    dynamic responseData;
    try {
      responseData = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      responseData = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    }

    String errorMessage = 'HTTP Error ${response.statusCode}';
    if (responseData is Map) {
      final detail = responseData['detail'] ?? responseData['message'] ?? responseData['error'];
      if (detail is List) {
        errorMessage = detail.map((e) => e['msg'] ?? e.toString()).join(' | ');
      } else if (detail != null) {
        errorMessage = detail.toString();
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      errorMessage = responseData;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      data: responseData,
    );
  }

  Future<bool> checkHealth() async {
    try {
      final res = await request(method: 'GET', path: ApiConstants.health);
      return res != null;
    } catch (_) {
      try {
        final res = await request(method: 'GET', path: ApiConstants.root);
        return res != null;
      } catch (_) {
        return false;
      }
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => message;
}
