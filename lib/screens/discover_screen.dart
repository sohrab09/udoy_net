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
  String? wifiName;
  String? wifiIP;
  String? subnet;
  List<Map<String, String>> connectedDevices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      fetchNetworkInfo();
    } else {
      print("Location permission denied");
    }
  }

  Future<void> fetchNetworkInfo() async {
    final name = await _networkInfo.getWifiName();
    final ip = await _networkInfo.getWifiIP();

    if (ip != null) {
      subnet = ip.substring(0, ip.lastIndexOf('.'));
    }

    setState(() {
      wifiName = name ?? "Unknown";
      wifiIP = ip ?? "Unknown";
    });

    if (subnet != null) {
      scanSubnet();
    } else {
      print("Subnet is null; scanning cannot proceed.");
    }
  }

  Future<void> scanSubnet() async {
    if (subnet == null) {
      print("No subnet available to scan.");
      return;
    }

    setState(() {
      connectedDevices.clear();
      isScanning = true;
    });

    List<Future<void>> pingFutures = [];

    for (int i = 1; i <= 254; i++) {
      final ip = '$subnet.$i';
      final ping = Ping(ip, count: 1, timeout: 2000, interval: 100);

      pingFutures.add(_pingDevice(ping, ip));
    }

    await Future.wait(pingFutures);

    setState(() {
      isScanning = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Discover Screen"),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Updated Wi-Fi Info Card Design
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi, color: Colors.blue, size: 30),
                        SizedBox(width: 10),
                        Text('Wi-Fi Information',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.network_wifi,
                            color: Colors.blueAccent, size: 20),
                        SizedBox(width: 10),
                        Text('Wi-Fi Name:',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(wifiName ?? "Fetching...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.settings_input_component,
                            color: Colors.blueAccent,
                            size: 20), // Changed to a more appropriate icon
                        SizedBox(width: 10),
                        Text('Device IP:',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(wifiIP ?? "Fetching...",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            // Scan Button
            isScanning
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: fetchNetworkInfo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Refresh & Scan',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
            SizedBox(height: 20),
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
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: EdgeInsets.only(top: 10),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text('${device['name']} (${device['ip']})'),
                      subtitle: Text('Ping Status: ${device['pingStatus']}'),
                      leading: Icon(Icons.device_hub, color: Colors.blueAccent),
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
    );
  }
}
