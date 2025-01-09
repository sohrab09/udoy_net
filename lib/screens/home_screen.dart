import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:dart_ping/dart_ping.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _wifiName = 'Unknown';
  String _deviceIP = 'Unknown';
  String _wifiBroadcast = 'Unknown';
  String _deviceGateway = 'Unknown';
  String _wifiSubmask = 'Unknown';
  String pingResult = "Ping result will be shown here";

  final NetworkInfo _networkInfo = NetworkInfo();

  @override
  void initState() {
    super.initState();
    _initNetworkInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Info'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(Icons.wifi, 'Wifi Name', _wifiName),
                      _buildInfoRow(Icons.perm_device_information, 'Device IP',
                          _deviceIP),
                      _buildInfoRow(Icons.broadcast_on_home, 'Wifi Broadcast',
                          _wifiBroadcast),
                      _buildInfoRow(
                          Icons.router, 'Device Gateway', _deviceGateway),
                      _buildInfoRow(
                          Icons.subtitles, 'Wifi Submask', _wifiSubmask),
                    ],
                  ),
                ),
              ),
              // Ping result display
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  pingResult,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: startPing,
                child: Text('Ping'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initNetworkInfo() async {
    String? wifiName, wifiIPv4, wifiBroadcast, wifiGatewayIP, wifiSubmask;

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
      wifiBroadcast = await _networkInfo.getWifiBroadcast();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi broadcast', error: e);
      wifiBroadcast = 'Failed to get Wifi broadcast';
    }

    try {
      wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi gateway address', error: e);
      wifiGatewayIP = 'Failed to get Wifi gateway address';
    }

    try {
      wifiSubmask = await _networkInfo.getWifiSubmask();
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi submask address', error: e);
      wifiSubmask = 'Failed to get Wifi submask address';
    }

    setState(() {
      _wifiName = wifiName ?? 'Unknown';
      _deviceIP = wifiIPv4 ?? 'Unknown';
      _wifiBroadcast = wifiBroadcast ?? 'Unknown';
      _deviceGateway = wifiGatewayIP ?? 'Unknown';
      _wifiSubmask = wifiSubmask ?? 'Unknown';
    });
  }

  void startPing() async {
    final ping = Ping('8.8.8.8', count: 4);
    ping.stream.listen((event) {
      print(event);
      setState(() {
        pingResult = event.toString();
      });
    });
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.blueAccent),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
