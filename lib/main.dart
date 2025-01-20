import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:udoy_net/screens/discover_connected_ip.dart';
import 'package:udoy_net/screens/login_screen.dart';
import 'package:udoy_net/screens/wifi_available.dart';
import 'dart:convert';
import 'screens/error_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/discover_screen.dart';
import 'widgets/custom_bottom_navigation_bar.dart';
import 'package:udoy_net/models/network_data.dart';
import 'screens/wifi_class.dart';
import 'package:udoy_net/utils/TokenManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the token is available
  final token = await TokenManager.getToken();

  // print('Token: $token');

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
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
  String _internetPublicIP = ''; // Store the public IP
  String? customerID;
  String? token;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([HomeScreen(), ScanScreen(), DiscoverScreen()]);

    // Fetch the public IP when the app starts
    _getPublicIP();
    _verifyIPAddress(_internetPublicIP);
    _fetchCustomerID();
    _fetchToken();
  }

  // fetch the customer ID
  Future<void> _fetchCustomerID() async {
    customerID = await TokenManager.getCustomerID();
  }

  // Fetch the token
  Future<void> _fetchToken() async {
    token = await TokenManager.getToken();
  }

  // Function to fetch the public IP
  Future<void> _getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org/'));
      if (response.statusCode == 200) {
        final String ip = response.body;
        await _verifyIPAddress(ip);
        setState(() {
          _internetPublicIP = ip;
        });
      }
    } catch (e) {
      setState(() {
        _internetPublicIP = 'Failed to get Public IP';
      });
    }
  }

  // Function to verify the IP address
  Future<void> _verifyIPAddress(String ipAddress) async {
    final url = Uri.parse(
        'https://api.udoyadn.com/api/Auth/GetUdoyNetworkStatus?ip=$ipAddress');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == false) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ErrorScreen()),
          );
        }
      } else {
        print('Request failed with status verify: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in IP verification: $e');
    }
  }

  // Function to handle submission and show loading spinner
  Future<void> handleSubmitData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    WifiClass wifiClass = WifiClass();
    IPScanner scanner = IPScanner();
    WifiAvailable wifi = WifiAvailable();

    NetworkData networkData = await wifiClass.getNetworkData();
    Map<String, bool> availableNetworks = await scanner.scanNetwork();
    List<Map<String, dynamic>>? connectedList = await wifi.getAvailableWifi();

    AllNetworkDataModel model = AllNetworkDataModel(
      customerCode: customerID!,
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
    String jsonBody = jsonEncode(jsonData);

    // print('JSON Data to submit: $jsonBody');

    final url = Uri.parse(
        'https://api.udoyadn.com/api/SelfcareApps/SaveCustomerNetworkData');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonBody,
      );

      if (response.statusCode == 200) {
        print('Data submitted successfully!');

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('Data submission failed!');

        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data submission failed!'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  // Function to handle logout
  Future<void> _logout() async {
    // Clear the token
    await TokenManager.logout();

    // Navigate to login screen
    Navigator.pushReplacementNamed(context, '/login');
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
        backgroundColor: const Color(0xFF65AA4B),
        elevation: 10,
        actions: <Widget>[
          // Submit button
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

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
        ],
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
