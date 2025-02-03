import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:udoy_net/classes/discover_connected_ip.dart';
import 'package:udoy_net/screens/discover_screen.dart';
// import 'package:udoy_net/screens/error_screen.dart';
import 'package:udoy_net/screens/home_screen.dart';
import 'package:udoy_net/screens/no_wifi.dart';
import 'package:udoy_net/screens/scan_screen.dart';
import 'package:udoy_net/classes/wifi_available.dart';
import 'package:udoy_net/classes/wifi_class.dart';
import 'package:udoy_net/widgets/custom_bottom_navigation_bar.dart';
import 'package:udoy_net/widgets/custom_drawer.dart';
import 'dart:convert';
import 'dart:async';
import 'package:udoy_net/models/network_data.dart';
import 'package:udoy_net/utils/TokenManager.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  int _currentIndex = 0;
  bool _isLoading = true; // Start with loading as true initially
  String _internetPublicIP = ''; // Store the public IP
  String? customerCode;
  String? token;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([HomeScreen(), ScanScreen(), DiscoverScreen()]);
    _initializeDataAsync();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _initializeDataAsync() {
    Future.microtask(() async {
      await _initializeData();
    });
  }

  Future<void> _initializeData() async {
    await _getPublicIPAddress();
    await _verifyIPAddress(_internetPublicIP);
    await _fetchCustomerID();
    await _fetchToken();
    if (mounted) {
      setState(() {
        _isLoading = false; // End loading once all initial data is fetched
      });
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
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
    if (navigatorKey.currentContext == null) return; // Add null check
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

  // fetch the customer ID
  Future<void> _fetchCustomerID() async {
    customerCode = await TokenManager.getCustomerCode();
  }

  // Fetch the token
  Future<void> _fetchToken() async {
    token = await TokenManager.getToken();
  }

  Future<void> _getPublicIPAddress() async {
    try {
      var ipAddress = IpAddress(type: RequestType.json);
      dynamic data = await ipAddress.getIpAddress();
      if (data['ip'] == null) {
        throw IpAddressException('Failed to get Public IP');
      }
      if (mounted) {
        setState(() {
          _internetPublicIP = data['ip'];
        });
      }
    } on IpAddressException catch (exception) {
      print(exception.message);
    }
  }

  // Function to verify the IP address
  Future<void> _verifyIPAddress(String ipAddress) async {
    if (ipAddress.isEmpty) return; // Skip verification if IP is empty
    final url = Uri.parse(
        'https://api.udoyadn.com/api/Auth/GetUdoyNetworkStatus?ip=$ipAddress');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == false && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NoWiFiPage()),
          );
          _handleConnectivityChange([ConnectivityResult.mobile]);
        }
      }
    } catch (e) {
      print('Error in IP verification: $e');
    }
  }

  // Function to handle submission and show loading spinner
  Future<void> handleSubmitData() async {
    if (mounted) {
      setState(() {
        _isLoading =
            true; // Start loading when the user clicks the submit button
      });
    }

    if (customerCode == null ||
        token == null ||
        customerCode!.isEmpty ||
        token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing customer ID or token'),
          backgroundColor: Colors.red,
        ),
      );
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading if data is missing
        });
      }
      return;
    }

    WifiClass wifiClass = WifiClass();
    IPScanner scanner = IPScanner();
    WifiAvailable wifi = WifiAvailable();

    NetworkData networkData = await wifiClass.getNetworkData();
    Map<String, bool> availableNetworks = await scanner.scanNetwork();
    List<Map<String, dynamic>>? connectedList = await wifi.getAvailableWifi();

    AllNetworkDataModel model = AllNetworkDataModel(
      customerCode: customerCode!,
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
      if (mounted) {
        setState(() {
          _isLoading = false; // End loading once the submission is done
        });
      }
    }
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
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 10,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (!_isLoading && mounted) {
            // Disable navigation if loading
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
      drawer: CustomDrawer(),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: () {
                if (!_isLoading) {
                  handleSubmitData();
                }
              },
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 30,
              ),
            ),
    );
  }
}
