import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _tokenKey = 'token';
  static const _customerIDKey = 'customerID';

  // Getters
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getCustomerID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerIDKey);
  }

  // Setters
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_tokenKey, token);
  }

  static Future<void> setCustomerID(String customerID) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_customerIDKey, customerID);
  }

  // To clear all saved data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_tokenKey);
    prefs.remove(_customerIDKey);
  }
}
