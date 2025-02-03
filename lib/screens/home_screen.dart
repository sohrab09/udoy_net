import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:udoy_net/components/ping_chart.dart';
import 'ping_service.dart';
import 'package:fl_chart/fl_chart.dart';

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

  double _gatewayPingMs = -1.0;
  double _internetPingMs = -1.0;

  List<FlSpot> gatewayPingData = [FlSpot(0, 0)];
  List<FlSpot> internetPingData = [FlSpot(0, 0)];

  final String _gatewayPingLabel = 'Gateway Ping';
  final String _internetPingLabel = 'Internet Ping';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    await Future.delayed(const Duration(seconds: 5)); // Add delay here
    _getPublicIPAddress(); // Fetch public IP first
    _getWifiInfo();
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
    try {
      String? wifiName = await _networkInfo.getWifiName();
      String? deviceIP = await _networkInfo.getWifiIP();
      String? deviceGateway = await _networkInfo.getWifiGatewayIP();

      if (mounted) {
        setState(() {
          _wifiName = wifiName ?? 'N/A';
          _deviceIP = deviceIP ?? 'N/A';
          _deviceGateway = deviceGateway ?? 'N/A';
          _isLoading = false;
        });
      }
    } catch (e) {
      _handleError('Failed to get network info', e);
    }
  }

  // get public IP
  Future<void> _getPublicIPAddress() async {
    try {
      developer.log('Fetching public IP address...');
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
      developer.log('Public IP address fetched: $_publicIP');
    } on IpAddressException catch (exception) {
      _handleError(exception.message, exception);
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
      _handleError('Failed to get WiFi details', e);
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
      int gatewayPingInt = -1;
      int internetPingInt = -1;

      // Ping the gateway
      if (_deviceGateway != "Unknown") {
        String gatewayPing = await PingService.ping(_deviceGateway);
        // Extract numeric value and convert it to an integer
        gatewayPingInt = _parsePingToInt(gatewayPing);
      }

      // Ping the internet
      String internetPing = await PingService.ping("8.8.8.8");
      // Extract numeric value and convert it to an integer
      internetPingInt = _parsePingToInt(internetPing);

      if (mounted) {
        _updatePingResults(gatewayPingInt, internetPingInt);
      }
    } catch (e) {
      if (mounted) {
        _updatePingResults(-1, -1); // In case of error, set ping results to -1
      }
    }
  }

  void _updatePingResults(int gatewayPingMs, int internetPingMs) {
    setState(() {
      _gatewayPingResult = gatewayPingMs != -1 ? "$gatewayPingMs ms" : "N/A";
      _internetPingResult = internetPingMs != -1 ? "$internetPingMs ms" : "N/A";
      _gatewayPingMs = gatewayPingMs.toDouble(); // Update this to double
      _internetPingMs = internetPingMs.toDouble(); // Update this to double

      // Add new data to the lists
      if (gatewayPingData.length > 5) {
        gatewayPingData.removeAt(0); // Keep last 5 data points
      }
      if (internetPingData.length > 5) {
        internetPingData.removeAt(0); // Keep last 5 data points
      }
      gatewayPingData.add(FlSpot(
          DateTime.now().millisecondsSinceEpoch.toDouble(), _gatewayPingMs));
      internetPingData.add(FlSpot(
          DateTime.now().millisecondsSinceEpoch.toDouble(), _internetPingMs));
    });
  }

  int _parsePingToInt(String pingResult) {
    final regex = RegExp(r'(\d+)'); // Match only digits
    final match = regex.firstMatch(pingResult);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '') ??
          0; // Parse and return integer
    }
    return 0; // Return 0 if parsing fails
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 5)); // Add delay here
    await _getWifiInfo();
    await _getPublicIPAddress();
    await _getWifiDetails();
    await _pingAll();

    setState(() => _isLoading = false);
  }

  bool _isPingDataAvailable() {
    return _gatewayPingResult != "N/A" && _internetPingResult != "N/A";
  }

  void _handleError(String message, dynamic error) {
    developer.log(message, error: error);
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
                      const SizedBox(height: 10),
                      _pingInfoCard(),
                      const SizedBox(height: 10),
                      _isPingDataAvailable()
                          ? PingChart(
                              gatewayPingData: gatewayPingData,
                              internetPingData: internetPingData,
                              gatewayPingLabel: _gatewayPingLabel,
                              internetPingLabel: _internetPingLabel)
                          : Container(), // Conditionally render the chart
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _wifiInfoCard() {
    return _buildCard(
      title: 'Wi-Fi Network Details',
      children: [
        _buildInfoRow(Icons.wifi, 'Wi-Fi Name', _wifiName),
        const Divider(),
        _buildInfoRow(Icons.perm_device_information, 'Device IP', _deviceIP),
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
    );
  }

  Widget _pingInfoCard() {
    return _buildCard(
      title: 'Ping Results',
      children: [
        _buildPingRow(
            Icons.router, 'Gateway: $_deviceGateway', _gatewayPingResult),
        const Divider(),
        _buildPingRow(Icons.public, 'Internet: 8.8.8.8', _internetPingResult),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String result) {
    Color signalStrengthColor = Colors.black87; // Default color

    // Add the signal strength color logic
    if (result == "Very Weak") {
      signalStrengthColor = Color(0xFFD60200); // Red for very weak signal
    } else if (result == "Poor") {
      signalStrengthColor = Color(0xFF015B71); // Blue for poor signal
    } else if (result == "Good") {
      signalStrengthColor = Color(0xFF4B4B91); // Purple for good signal
    } else if (result == "Excellent") {
      signalStrengthColor = Color(0xFF599E41); // Green for excellent signal
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
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
            result,
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
