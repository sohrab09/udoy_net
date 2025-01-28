import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:udoy_net/root_screen/home_page.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/utils/TokenManager.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  _enablePlatformOverrideForDesktop();
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
  @override
  void initState() {
    super.initState();
    _requestPermissions();
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
          print('Permission permanently denied. Redirecting to settings...');
          openAppSettings();
        }
      }
    } catch (e) {
      print('Permission error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
