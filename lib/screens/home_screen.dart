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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _wifiName = 'Unknown';
  String _deviceIP = 'Unknown';
  String _deviceGateway = 'Unknown';
  String _internetPublicIP = 'Unknown'; // New public IP variable

  String _gatewayPingResult = "N/A"; // Ping result for gateway
  String _internetPingResult = "N/A"; // Ping result for public IP

  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _initNetworkInfo().then((_) {
      // After network info is fetched, start pinging automatically
      _pingAll();
      _getPublicIP();
      // Set a timer to refresh the data every 5 seconds
      Timer.periodic(const Duration(seconds: 5), (timer) {
        _pingAll();
        _getPublicIP();
        setState(() {});
      });
    });
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

    // Get public IP
    _getPublicIP();
  }

  Future<void> _getPublicIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org/'));
      if (response.statusCode == 200) {
        final String ip = response.body;
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

  Future<void> _refreshData() async {
    setState(() {
      // Clear the data or show loading state by clearing values temporarily
      _wifiName = 'Loading...';
      _deviceIP = 'Loading...';
      _deviceGateway = 'Loading...';
      _internetPublicIP = 'Loading...';
      _gatewayPingResult = 'N/A';
      _internetPingResult = 'N/A';
    });
    await _initNetworkInfo();
    await _pingAll();
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                style: TextStyle(
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
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // Trigger the refresh
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Network Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.wifi, 'Wifi Name', _wifiName),
                        Divider(),
                        _buildInfoRow(Icons.perm_device_information,
                            'Device IP', _deviceIP),
                        Divider(),
                        _buildInfoRow(
                            Icons.router, 'Device Gateway', _deviceGateway),
                        Divider(),
                        _buildInfoRow(
                            Icons.public, 'Public IP', _internetPublicIP),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Ping Signal Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.router, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'Gateway: $_deviceGateway',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _gatewayPingResult,
                              style: TextStyle(
                                color: _gatewayPingResult == "N/A"
                                    ? Colors
                                        .red // Change color to red if ping result is "N/A"
                                    : (_gatewayPingResult == "Ping failed:"
                                        ? Colors.red
                                        : Colors.green),
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.public, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'Internet: 8.8.8.8',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _internetPingResult,
                              style: TextStyle(
                                color: _internetPingResult == "N/A"
                                    ? Colors.red
                                    : (_internetPingResult == "Ping failed:"
                                        ? Colors.red
                                        : Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
