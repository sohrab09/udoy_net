import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:udoy_net/root_screen/home_page.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/utils/TokenManager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udoy_net/classes/device_location.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final token = await TokenManager.getToken();

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Timer _locationCheckTimer;
  late Timer _logoutCheckTimer;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    DeviceLocation().forceOpenDeviceLocation(context);
    _startLocationCheckTimer();
    _startLogoutCheckTimer(); // Start the logout check timer
  }

  @override
  void dispose() {
    _locationCheckTimer.cancel();
    _logoutCheckTimer.cancel();
    super.dispose();
  }

  Future<void> _checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('permissionsRequested') ?? true;

    if (isFirstTime) {
      await _requestPermissions();
      await prefs.setBool('permissionsRequested', false);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.location.status;
      } else if (Platform.isIOS) {
        status = await Permission.locationWhenInUse.status;
      } else {
        return;
      }

      if (status.isDenied) {
        PermissionStatus requestStatus = Platform.isAndroid
            ? await Permission.location.request()
            : await Permission.locationWhenInUse.request();

        if (requestStatus.isPermanentlyDenied) {
          openAppSettings();
        }
      }
    } catch (e) {
      print('Permission error: $e');
    }
  }

  void _startLocationCheckTimer() {
    _locationCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      await _checkLocationStatus();
    });
  }

  Future<void> _checkLocationStatus() async {
    bool isLocationEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!isLocationEnabled) {
      DeviceLocation().forceOpenDeviceLocation(context);
    }
  }

  void _startLogoutCheckTimer() {
    _logoutCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await _checkLogoutTime();
    });
  }

  Future<void> _checkLogoutTime() async {
    final lastLoginDateString = await TokenManager.getLastLoginDate();
    if (lastLoginDateString != null && lastLoginDateString.isNotEmpty) {
      DateTime lastLoginDate = DateTime.parse(lastLoginDateString);
      DateTime now = DateTime.now();
      if (now.day != lastLoginDate.day ||
          now.month != lastLoginDate.month ||
          now.year != lastLoginDate.year) {
        _logoutUser();
        print('User logged out due to date change');
      }
    }
  }

  void _logoutUser() {
    TokenManager.logout();
    navigatorKey.currentState?.pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: widget.isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
