import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udoy_net/models/network_data.dart';
import 'package:http/http.dart' as http;
import 'ping_service.dart';

class WifiClass {
  get developer => null;

  static const platform = MethodChannel('com.example.udoy_net/linkSpeed');

  // Utility function to handle network-related error
  Future<String> getDataFromNetwork(
      Function networkCall, String errorMessage) async {
    try {
      return await networkCall();
    } catch (e) {
      developer.log(errorMessage, error: e);
      return errorMessage;
    }
  }

  // Signal strength description
  String getSignalStrengthDescription(int? signalStrength) {
    if (signalStrength == 1 || signalStrength == null) return "Very Weak";
    if (signalStrength == 4) return "Excellent";
    if (signalStrength == 3) return "Good";
    if (signalStrength == 2) return "Poor";
    return "N/A";
  }

  Future<NetworkData> getNetworkData() async {
    final NetworkInfo _networkInfo = NetworkInfo();

    // Initialize network data variables
    String wifiName = '', wifiIPv4 = '', wifiGatewayIP = '', publicIP = '';
    String linkSpeed = '', signalStrength = '', frequency = '', rssi = '';
    String gatewayPing = '', internetPing = '';

    // Get the wifi name
    wifiName = await getDataFromNetwork(
      () async {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          if (await Permission.locationWhenInUse.request().isGranted) {
            return await _networkInfo.getWifiName() ?? '';
          } else {
            return 'Unauthorized to get Wifi Name';
          }
        } else {
          return await _networkInfo.getWifiName() ?? '';
        }
      },
      'Failed to get Wifi Name',
    );

    // Get the wifi IPv4 address
    wifiIPv4 = await getDataFromNetwork(
      () async => await _networkInfo.getWifiIP() ?? '',
      'Failed to get Wifi IPv4',
    );

    // Get the wifi gateway address
    wifiGatewayIP = await getDataFromNetwork(
      () async => await _networkInfo.getWifiGatewayIP() ?? '',
      'Failed to get Wifi gateway address',
    );

    // Get the public IP address
    publicIP = await getDataFromNetwork(
      () async {
        final response = await http.get(Uri.parse('https://api.ipify.org'));
        return response.body;
      },
      'Failed to get public IP',
    );

    // Get the wifi link speed, signal strength, frequency, and RSSI
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod('getWifiDetails');
      linkSpeed = "${result['linkSpeed']} Mbps";
      signalStrength = getSignalStrengthDescription(result['signalStrength']);
      frequency = "${result['frequency']} MHz";
      rssi = "${result['rssi']} dBm";
    } on PlatformException catch (e) {
      developer.log('Failed to get WiFi details', error: e);
    }

    // Ping the gateway and internet
    gatewayPing = await getDataFromNetwork(
      () async => await PingService.ping(wifiGatewayIP),
      'Failed to ping gateway',
    );

    internetPing = await getDataFromNetwork(
      () async => await PingService.ping('8.8.8.8'),
      'Failed to ping internet',
    );

    // Return a populated NetworkData object
    return NetworkData(
      wifiName: wifiName,
      deviceIP: wifiIPv4,
      gateway: wifiGatewayIP,
      publicIP: publicIP,
      linkSpeed: linkSpeed,
      signalStrength: signalStrength,
      freequency: frequency,
      rssi: rssi,
      gatewayPing: gatewayPing,
      internetPing: internetPing,
    );
  }
}
