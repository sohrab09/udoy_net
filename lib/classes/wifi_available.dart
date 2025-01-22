import 'package:wifi_scan/wifi_scan.dart';
import 'dart:async';

class WifiAvailable {
  Future<List<Map<String, dynamic>>> getAvailableWifi() async {
    List<Map<String, dynamic>> availableNetworks = [];
    if (await WiFiScan.instance.canStartScan() == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();

      availableNetworks = results
          .map((network) => {
                'ssid': network.ssid,
                'signalStrength': network.level,
                'frequency': network.frequency,
              })
          .toList();
    } else {}

    return availableNetworks;
  }
}
