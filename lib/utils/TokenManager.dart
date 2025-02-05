import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _tokenKey = 'token';
  static const _customerCode = 'customerCode';
  static const _customerNameKey = 'customerName';
  static const _distributorName = 'distributorName';
  static const _resellerName = 'resellerName';
  static const _pppoeUserid = 'pppoeUserid';
  static const _pppoePassword = 'pppoePassword';
  static const _balance = 'balance';
  static const _billAmount = 'billAmount';
  static const _routerIp = 'routerIp';
  static const _expireDate = 'expireDate';
  static const _loginTime = 'loginTime';
  static const _lastLoginDateKey = 'lastLoginDate';

  // Getters
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getCustomerCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerCode);
  }

  static Future<String?> getCustomerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customerNameKey);
  }

  static Future<String?> getDistributorName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_distributorName);
  }

  static Future<String?> getResellerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_resellerName);
  }

  static Future<String?> getPppoeUserid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pppoeUserid);
  }

  static Future<String?> getPppoePassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pppoePassword);
  }

  static Future<String?> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_balance);
  }

  static Future<String?> getBillAmount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_billAmount);
  }

  static Future<String?> getRouterIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_routerIp);
  }

  static Future<String?> getExpireDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_expireDate);
  }

  static Future<String?> getLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_loginTime);
  }

  static Future<String?> getLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastLoginDateKey);
  }

  // Setters
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_tokenKey, token);
  }

  static Future<void> setCustomerCode(String customerID) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_customerCode, customerID);
  }

  static Future<void> setCustomerName(String customerName) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_customerNameKey, customerName);
  }

  static Future<void> setDistributorName(String distributorName) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_distributorName, distributorName);
  }

  static Future<void> setResellerName(String resellerName) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_resellerName, resellerName);
  }

  static Future<void> setPppoeUserid(String pppoeUserid) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_pppoeUserid, pppoeUserid);
  }

  static Future<void> setPppoePassword(String pppoePassword) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_pppoePassword, pppoePassword);
  }

  static Future<void> setBalance(String balance) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_balance, balance);
  }

  static Future<void> setBillAmount(String billAmount) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_billAmount, billAmount);
  }

  static Future<void> setRouterIp(String routerIp) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_routerIp, routerIp);
  }

  static Future<void> setExpireDate(String expireDate) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_expireDate, expireDate);
  }

  static Future<void> setLoginTime(String loginTime) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_loginTime, loginTime);
  }

  static Future<void> setLastLoginDate(String date) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_lastLoginDateKey, date);
  }

  // Getters

  // To clear all saved data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_tokenKey);
    prefs.remove(_customerCode);
    prefs.remove(_customerNameKey);
    prefs.remove(_distributorName);
    prefs.remove(_resellerName);
    prefs.remove(_pppoeUserid);
    prefs.remove(_pppoePassword);
    prefs.remove(_balance);
    prefs.remove(_billAmount);
    prefs.remove(_routerIp);
    prefs.remove(_expireDate);
    prefs.remove(_loginTime);
    prefs.remove(_lastLoginDateKey);
  }
}
