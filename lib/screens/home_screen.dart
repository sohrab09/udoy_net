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

  @override
  void initState() {
    super.initState();
    _initNetworkInfo().then((_) {
      _pingAll();
      _getPublicIP();
      _getWifiDetails();

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
    if (signalStrength == null) return "Very Weak";
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
            style: const TextStyle(
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
        onRefresh: _initNetworkInfo,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.wifi, 'WiFi Name', _wifiName),
                        Divider(),
                        _buildInfoRow(Icons.perm_device_information,
                            'Device IP', _deviceIP),
                        Divider(),
                        _buildInfoRow(Icons.router, 'Gateway', _deviceGateway),
                        Divider(),
                        _buildInfoRow(
                            Icons.public, 'Public IP', _internetPublicIP),
                        Divider(),
                        _buildInfoRow(
                            Icons.network_check, 'Link Speed', _linkSpeed),
                        Divider(),
                        _buildInfoRow(Icons.signal_cellular_alt,
                            'Signal Strength', _signalStrength),
                        Divider(),
                        _buildInfoRow(Icons.wifi, 'Frequency', _frequency),
                        Divider(),
                        _buildInfoRow(Icons.wifi_lock, 'RSSI', _rssi),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
