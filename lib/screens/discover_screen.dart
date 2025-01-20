import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dart_ping/dart_ping.dart';
import 'dart:io';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  _DiscoverScreenState createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String? subnet;
  List<Map<String, String>> connectedDevices = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  // Request location permission
  Future<void> requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      fetchNetworkInfo();
    } else {
      print("Location permission denied");
    }
  }

  // Fetch Network Info
  Future<void> fetchNetworkInfo() async {
    final ip = await _networkInfo.getWifiIP();
    if (ip != null) {
      subnet = ip.substring(0, ip.lastIndexOf('.'));
      scanSubnet();
    } else {
      print("IP address is null; scanning cannot proceed.");
    }
  }

  // Scan subnet and find connected devices
  Future<void> scanSubnet() async {
    if (subnet == null) {
      print("No subnet available to scan.");
      return;
    }

    connectedDevices.clear();

    List<Future<void>> pingFutures = [];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      final ping = Ping(ip, count: 1, timeout: 500, interval: 10);

      pingFutures.add(_pingDevice(ping, ip));
    }

    await Future.wait(pingFutures);

    setState(() {});
  }

  // Ping a device to check if it is online
  Future<void> _pingDevice(Ping ping, String ip) async {
    await for (final event in ping.stream) {
      if (event.response != null) {
        String? hostName = await getDeviceName(ip);
        setState(() {
          connectedDevices.add({
            'ip': ip,
            'name': hostName ?? 'Unknown',
            'pingStatus': 'Online',
          });
        });
      }
    }
  }

  // Lookup device name by IP
  Future<String?> getDeviceName(String ip) async {
    try {
      final result = await InternetAddress.lookup(ip);
      if (result.isNotEmpty && result[0].host.isNotEmpty) {
        return result[0].host; // Return hostname if available
      }
    } catch (e) {
      print("Error looking up $ip: $e");
    }
    return null;
  }

  // Pull-to-refresh function
  Future<void> _onRefresh() async {
    await fetchNetworkInfo(); // Manually refresh the devices
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh, // Pull-to-refresh triggers this function
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Connected Devices: ${connectedDevices.length}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: connectedDevices.length,
                  itemBuilder: (context, index) {
                    var device = connectedDevices[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: EdgeInsets.only(top: 5),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(5),
                        title: Text('${device['ip']}'),
                        subtitle: Text('Ping Status: ${device['pingStatus']}'),
                        leading:
                            Icon(Icons.device_hub, color: Colors.blueAccent),
                        trailing: Icon(
                          Icons.network_check,
                          color: device['pingStatus'] == 'Online'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
