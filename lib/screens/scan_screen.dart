import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  Timer? scanTimer;

  @override
  void initState() {
    super.initState();
    _startScanning();
    _setupPeriodicScan();
  }

  @override
  void dispose() {
    scanTimer?.cancel();
    super.dispose();
  }

  Future<void> _startScanning() async {
    final canStartScan = await WiFiScan.instance.canStartScan();
    if (canStartScan == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      _getScannedResults();
    }
  }

  Future<void> _getScannedResults() async {
    final canGetResults = await WiFiScan.instance.canGetScannedResults();
    if (canGetResults == CanGetScannedResults.yes) {
      final results = await WiFiScan.instance.getScannedResults();
      if (mounted) {
        setState(() {
          accessPoints = results;
        });
      }
    }
  }

  void _setupPeriodicScan() {
    scanTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _startScanning();
    });
  }

  Color _getSignalColor(int level) {
    if (level > -50) {
      return const Color(0xFF599E41); // Green
    } else if (level <= -50 && level >= -60) {
      return const Color(0xFF4B4B91); // Blueish-purple
    } else if (level <= -61 && level >= -70) {
      return const Color(0xFF015B71); // Teal
    } else {
      return const Color(0xFFD60200); // Red
    }
  }

  // Refresh method to reload data when user pulls down
  Future<void> _refreshData() async {
    await _startScanning();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // Trigger data refresh on pull down
        child: accessPoints.isEmpty
            ? const Center(child: Text("No nearby Wi-Fi networks found."))
            : ListView.builder(
                itemCount: accessPoints.length,
                itemBuilder: (context, index) {
                  final ap = accessPoints[index];
                  final signalColor = _getSignalColor(ap.level);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 2.0),
                          leading: Icon(
                            Icons.wifi,
                            color: signalColor,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ap.ssid.isNotEmpty
                                          ? ap.ssid
                                          : "**EMPTY**",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text("Frequency: ${ap.frequency} MHz"),
                                  ],
                                ),
                              ),
                              Text(
                                "${ap.level} dBm",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      signalColor, // Apply color to the level text
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(), // Add divider after each list item
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
