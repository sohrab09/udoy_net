import 'dart:convert';
import 'package:http/http.dart' as http;
import 'TokenManager.dart'; // Import the TokenManager class
import 'dart:async';

class ApiClient {
  static const String baseUrl = "https://api.udoyadn.com";
  static bool isRefreshing = false;
  static List<Function> refreshSubscribers = [];
  String date = '';
  String time = '';

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

  Future<void> getDateTime() async {
    final url = Uri.parse('$baseUrl/api/Auth/GetDateTime');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = response.body.trim();
        final dateParts = data.split(' ')[0].split('/');
        final timeParts = data.split(' ')[1].split(':');
        final period = data.split(' ')[2];

        final date = dateParts[0];
        int hour = int.parse(timeParts[0]);
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }

        final formattedHour = hour.toString().padLeft(2, '0');

        this.date = '$date-${dateParts[1]}-${dateParts[2]}';
        time = '$formattedHour:${timeParts[1]}:${timeParts[2]}';
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _refreshToken() async {
    // Call your API to refresh the token
    final userId = await TokenManager.getCustomerCode();
    final password = await getDateTime();

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

  // add a method to post data to the API
  Future<http.Response> postData(String url, Map<String, dynamic> data) async {
    return await request('POST', url, body: data);
  }
}
