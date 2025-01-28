import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'ping_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.udoy_net/linkSpeed');

  final NetworkInfo _networkInfo = NetworkInfo();
  Timer? _periodicTimer;
  bool _isLoading = true;
  String _wifiName = 'N/A';
  String _deviceIP = 'N/A';
  String _deviceGateway = 'N/A';
  String _publicIP = 'N/A';
  String _linkSpeed = 'N/A';
  String _signalStrength = 'N/A';
  String _frequency = 'N/A';
  String _rssi = 'N/A';
  String _gatewayPingResult = "N/A";
  String _internetPingResult = "N/A";

  @override
  void initState() {
    super.initState();
    _getWifiInfo();
    _getPublicIPAddress();
    _getWifiDetails();
    _pingAll();

    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _pingAll();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  // get wifi info
  Future<void> _getWifiInfo() async {
    String? wifiName;
    String? deviceIP;
    String? deviceGateway;

    try {
      wifiName = await _networkInfo.getWifiName();
      deviceIP = await _networkInfo.getWifiIP();
      deviceGateway = await _networkInfo.getWifiGatewayIP();
    } catch (e) {
      developer.log('Failed to get network info: $e');
    }

    if (mounted) {
      setState(() {
        _wifiName = wifiName ?? 'N/A';
        _deviceIP = deviceIP ?? 'N/A';
        _deviceGateway = deviceGateway ?? 'N/A';
        _isLoading = false;
      });
    }
  }

  // get public IP
  Future<void> _getPublicIPAddress() async {
    try {
      var ipAddress = IpAddress(type: RequestType.json);
      dynamic data = await ipAddress.getIpAddress();
      if (data['ip'] == null) {
        throw IpAddressException('Failed to get Public IP');
      }
      if (mounted) {
        setState(() {
          _publicIP = data['ip'] ?? 'N/A';
        });
      }
    } on IpAddressException catch (exception) {
      print(exception.message);
    }
  }

  // get signal strength
  Future<void> _getWifiDetails() async {
    try {
      final Map wifiDetails =
          await platform.invokeMethod('getWifiDetails') as Map;

      if (mounted) {
        setState(() {
          _linkSpeed = "${wifiDetails['linkSpeed']} Mbps";
          _signalStrength =
              _getSignalStrengthDescription(wifiDetails['signalStrength']);
          _frequency = "${wifiDetails['frequency']} MHz";
          _rssi = "${wifiDetails['rssi']} dBm";
        });
      }
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

  // ping all method

  Future<void> _pingAll() async {
    try {
      if (_deviceGateway != "Unknown") {
        final gatewayPing = await PingService.ping(_deviceGateway);
        if (mounted) {
          // Ensure the widget is still mounted
          setState(() {
            _gatewayPingResult = gatewayPing.isNotEmpty ? gatewayPing : "N/A";
          });
        }
      } else {
        if (mounted) {
          // Ensure the widget is still mounted
          setState(() {
            _gatewayPingResult = "N/A";
          });
        }
      }
      final internetPing = await PingService.ping("8.8.8.8");
      if (mounted) {
        // Ensure the widget is still mounted
        setState(() {
          _internetPingResult = internetPing.isNotEmpty ? internetPing : "N/A";
        });
      }
    } catch (e) {
      if (mounted) {
        // Ensure the widget is still mounted
        setState(() {
          _gatewayPingResult = "N/A";
          _internetPingResult = "N/A";
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    await _getWifiInfo();
    await _getPublicIPAddress();
    await _getWifiDetails();
    await _pingAll();

    setState(() => _isLoading = false);
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
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _wifiInfoCard(),
                      const SizedBox(height: 20),
                      _pingInfoCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _wifiInfoCard() {
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
            _buildInfoRow(Icons.public, 'Public IP', _publicIP),
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

  Widget _pingInfoCard() {
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
