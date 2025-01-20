import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'ping_service.dart';
// import 'dart:convert';
// import 'package:udoy_net/screens/error_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.udoy_net/linkSpeed');

  String _wifiName = 'Unknown';
  String _deviceIP = 'Unknown';
  String _deviceGateway = 'Unknown';
  String _internetPublicIP = 'Unknown';

  String _gatewayPingResult = "N/A";
  String _internetPingResult = "N/A";

  String _linkSpeed = 'Unknown';
  String _signalStrength = 'Unknown';
  String _frequency = 'Unknown';
  String _rssi = 'Unknown';

  final NetworkInfo _networkInfo = NetworkInfo();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    await _initNetworkInfo();
    await _pingAll();
    await _getPublicIP();
    await _getWifiDetails();
    // await _verifyIPAddress(_internetPublicIP);

    // recall the _pingAll method after 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _pingAll();
    });

    setState(() => _isLoading = false);
  }

  Future<void> _initNetworkInfo() async {
    String? wifiName, wifiIPv4, wifiGatewayIP;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (await Permission.locationWhenInUse.request().isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }

    try {
      wifiIPv4 = await _networkInfo.getWifiIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi IPv4', error: e);
      wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    setState(() {
      _wifiName = wifiName ?? 'Unknown';
      _deviceIP = wifiIPv4 ?? 'Unknown';
      _deviceGateway = wifiGatewayIP ?? 'Unknown';
    });
  }

  Future<void> _getWifiDetails() async {
    try {
      final Map wifiDetails =
          await platform.invokeMethod('getWifiDetails') as Map;

      setState(() {
        _linkSpeed = "${wifiDetails['linkSpeed']} Mbps";
        _signalStrength =
            _getSignalStrengthDescription(wifiDetails['signalStrength']);
        _frequency = "${wifiDetails['frequency']} MHz";
        _rssi = "${wifiDetails['rssi']} dBm";
      });
    } on PlatformException catch (e) {
      developer.log('Failed to get WiFi details', error: e);
      setState(() {
        _linkSpeed = 'Error';
        _signalStrength = 'Error';
        _frequency = 'Error';
        _rssi = 'Error';
      });
    }
  }

  String _getSignalStrengthDescription(int? signalStrength) {
    if (signalStrength == 1 || signalStrength == null) return "Very Weak";
    if (signalStrength == 4) return "Excellent";
    if (signalStrength == 3) return "Good";
    if (signalStrength == 2) return "Poor";
    return "N/A";
  }

  Future<void> _getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org/'));
      if (response.statusCode == 200) {
        final String ip = response.body;
        // await _verifyIPAddress(ip);
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

  // Future<void> _verifyIPAddress(String ipAddress) async {
  //   final url = Uri.parse(
  //       'https://api.udoyadn.com/api/Auth/GetUdoyNetworkStatus?ip=$ipAddress');
  //   // 'https://api.udoyadn.com/api/Auth/GetUdoyNetworkStatus?ip=202.51.180.246');

  //   try {
  //     final response = await http.post(
  //       url,
  //       headers: {'Content-Type': 'application/json'},
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data == false) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => ErrorScreen()),
  //         );
  //       }
  //     } else {
  //       print('Request failed with status verify: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error in IP verification: $e');
  //   }
  // }

  Future<void> _pingAll() async {
    try {
      if (_deviceGateway != "Unknown") {
        final gatewayPing = await PingService.ping(_deviceGateway);
        setState(() {
          _gatewayPingResult = gatewayPing.isNotEmpty ? gatewayPing : "N/A";
        });
      } else {
        setState(() {
          _gatewayPingResult = "N/A";
        });
      }
      final internetPing = await PingService.ping("8.8.8.8");
      setState(() {
        _internetPingResult = internetPing.isNotEmpty ? internetPing : "N/A";
      });
    } catch (e) {
      setState(() {
        _gatewayPingResult = "N/A";
        _internetPingResult = "N/A";
      });
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    Color signalStrengthColor = Colors.black87; // Default color

    // Add the signal strength color logic
    if (value == "Very Weak") {
      signalStrengthColor = Color(0xFFD60200); // Red for very weak signal
    } else if (value == "Poor") {
      signalStrengthColor = Color(0xFF015B71); // Blue for poor signal
    } else if (value == "Good") {
      signalStrengthColor = Color(0xFF4B4B91); // Purple for good signal
    } else if (value == "Excellent") {
      signalStrengthColor = Color(0xFF599E41); // Green for excellent signal
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 30, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: signalStrengthColor, // Apply the dynamic color here
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initialize,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildPingCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wi-Fi Network Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.wifi, 'Wi-Fi Name', _wifiName),
            const Divider(),
            _buildInfoRow(
                Icons.perm_device_information, 'Device IP', _deviceIP),
            const Divider(),
            _buildInfoRow(Icons.router, 'Gateway', _deviceGateway),
            const Divider(),
            _buildInfoRow(Icons.public, 'Public IP', _internetPublicIP),
            const Divider(),
            _buildInfoRow(Icons.speed, 'Link Speed', _linkSpeed),
            const Divider(),
            _buildInfoRow(
                Icons.signal_wifi_4_bar, 'Signal Strength', _signalStrength),
            const Divider(),
            _buildInfoRow(Icons.network_wifi, 'Frequency', _frequency),
            const Divider(),
            _buildInfoRow(Icons.network_cell, 'RSSI', _rssi),
          ],
        ),
      ),
    );
  }

  Widget _buildPingCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ping Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 8),
            _buildPingRow(
                Icons.router, 'Gateway: $_deviceGateway', _gatewayPingResult),
            const Divider(),
            _buildPingRow(
                Icons.public, 'Internet: 8.8.8.8', _internetPingResult),
          ],
        ),
      ),
    );
  }

  Widget _buildPingRow(IconData icon, String label, String result) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          result,
          style: TextStyle(
            color: result == "N/A" || result == "Ping Failed"
                ? Colors.red
                : Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
