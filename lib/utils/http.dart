import 'dart:convert';
import 'package:http/http.dart' as http;
import 'TokenManager.dart'; // Import the TokenManager class
import 'dart:async';

class ApiClient {
  static const String baseUrl = "https://api.udoyadn.com";
  static bool isRefreshing = false;
  static List<Function> refreshSubscribers = [];

  final http.Client client;

  ApiClient({required this.client});

  Future<Map<String, String>> _getHeaders() async {
    String? token = await TokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> request(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    var headers = await _getHeaders();
    Uri uri = Uri.parse('$baseUrl$url');

    try {
      http.Response response;
      if (method == 'POST') {
        response =
            await client.post(uri, headers: headers, body: json.encode(body));
      } else if (method == 'GET') {
        response = await client.get(uri, headers: headers);
      } else {
        response =
            await client.put(uri, headers: headers, body: json.encode(body));
      }

      if (response.statusCode == 401) {
        if (!isRefreshing) {
          isRefreshing = true;
          await _refreshToken();
        }
        return await _retryRequest(method, url, body);
      }

      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _refreshToken() async {
    // Call your API to refresh the token
    final userId = await TokenManager.getToken();
    final password = DateTime.now()
        .toString(); // Example of getting password (use your logic)

    final data = {
      'userID': 'CUS$userId',
      'password': password,
      'userIp': 'string',
      'userLocation': {'latitude': 'string', 'longitude': 'string'},
      'userPlatform': 'string',
      'userBrowser': 'string',
      'captchaValue': true,
    };

    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/Auth/GetAuthToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        await TokenManager.setToken(token);
        _onTokenRefreshed(token);
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (error) {
      rethrow;
    } finally {
      isRefreshing = false;
    }
  }

  Future<http.Response> _retryRequest(
      String method, String url, Map<String, dynamic>? body) async {
    return await request(method, url, body: body);
  }

  void _onTokenRefreshed(String token) {
    for (var subscriber in refreshSubscribers) {
      subscriber(token);
    }
    refreshSubscribers.clear();
  }

  void subscribeToTokenRefresh(Function(String) callback) {
    refreshSubscribers.add(callback);
  }
}
