import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/custom_bottom_navigation_bar.dart';
import 'package:udoy_net/models/network_data.dart';
import 'dart:convert';
import 'screens/wifi_class.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomeScreen(),
      ScanScreen(),
      DiscoverScreen(),
    ]);
  }

  void handleSubmitData(String data) async {
    WifiClass wifiClass = WifiClass();
    try {
      NetworkData networkData = await wifiClass.getNetworkData();
      String jsonData = jsonEncode(networkData.toJson());
      print('JSON Data: $jsonData');
    } catch (error) {
      print('Error occurred: $error');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "UDOY Internet",
          style: TextStyle(
              fontSize: 24,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
              wordSpacing: 2,
              shadows: [
                Shadow(
                  offset: Offset(2, 2),
                  blurRadius: 3,
                ),
              ]),
        ),
        titleSpacing: 0,
        toolbarHeight: 60,
        backgroundColor: const Color(0xFF65AA4B),
        elevation: 10,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 30),
            tooltip: 'Show Snackbar',
            onPressed: () {
              if (mounted) {
                handleSubmitData('');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}
