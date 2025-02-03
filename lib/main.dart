import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:udoy_net/root_screen/home_page.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/screens/no_wifi.dart';
import 'package:udoy_net/utils/TokenManager.dart';
// import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
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

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    Future.microtask(() {
      for (var result in results) {
        if (result == ConnectivityResult.mobile) {
          print("Connected to Mobile $results");
          _showNoWifiDialog();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NoWiFiPage()),
          );
        } else if (result == ConnectivityResult.wifi) {
          // Optionally handle Wi-Fi-specific logic if required
          print("Connected to Wi-Fi $results");
        }
      }
    });
  }

  void _showNoWifiDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('No Wi-Fi Connection'),
          content: Text(
              'You are not connected to Wi-Fi. Please check your connection.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
