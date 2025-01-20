import 'package:flutter/material.dart';
import 'package:udoy_net/screens/discover_connected_ip.dart';
import 'package:udoy_net/screens/wifi_available.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/discover_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/custom_bottom_navigation_bar.dart';
import 'package:udoy_net/models/network_data.dart';
import 'screens/wifi_class.dart';
import 'dart:convert'; // Import for jsonEncode

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
  bool _isLoading = false; // Loading state variable

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

  // Function to handle submission and show loading spinner
  void handleSubmitData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    WifiClass wifiClass = WifiClass();
    IPScanner scanner = IPScanner();
    WifiAvailable wifi = WifiAvailable();

    try {
      // Fetching network data
      NetworkData networkData = await wifiClass.getNetworkData();

      // Scanning available networks
      Map<String, bool> availableNetworks = await scanner.scanNetwork();

      // Fetching connected Wi-Fi list
      List<Map<String, dynamic>>? connectedList = await wifi.getAvailableWifi();

      // Creating the data model
      AllNetworkDataModel model = AllNetworkDataModel(
        customerCode: '123456',
        networkData: networkData,
        connectedList: availableNetworks,
        availableNetworks: connectedList,
      );

      // Structuring the data as a Map to convert it to JSON
      Map<String, dynamic> jsonData = {
        "customerCode": model.customerCode,
        "networkData": {
          "wifiName": model.networkData.wifiName,
          "deviceIP": model.networkData.deviceIP,
          "gateway": model.networkData.gateway,
          "publicIP": model.networkData.publicIP,
          "linkSpeed": model.networkData.linkSpeed,
          "signalStrength": model.networkData.signalStrength,
          "frequency": model.networkData.freequency,
          "rssi": model.networkData.rssi,
          "gatewayPing": model.networkData.gatewayPing,
          "internetPing": model.networkData.internetPing,
        },
        "availableNetworks": model.availableNetworks,
        "connectedList": model.connectedList,
        "connectedListCount": model.connectedList.length,
      };

      // Convert the data to JSON format
      String jsonString = jsonEncode(jsonData);

      // Print or use the JSON data
      print('JSON Data to submit: $jsonString');

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      print('Error occurred: $error');

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data submission failed!'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
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
            icon: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white) // Show loading spinner
                : const Icon(Icons.send, color: Colors.white, size: 30),
            tooltip: 'Submit Data',
            onPressed: _isLoading // Disable button if loading
                ? null
                : () {
                    if (mounted) {
                      handleSubmitData();
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
