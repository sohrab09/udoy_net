class AllNetworkDataModel {
  String customerCode;
  NetworkData networkData;
  Map<String, bool> connectedList;
  List<Map<String, dynamic>>? availableNetworks;

  AllNetworkDataModel({
    required this.customerCode,
    required this.networkData,
    required this.connectedList,
    required this.availableNetworks,
  });
}

class NetworkData {
  final String wifiName;
  final String deviceIP;
  final String gateway;
  final String publicIP;
  final String linkSpeed;
  final String signalStrength;
  final String freequency;
  final String rssi;
  final String gatewayPing;
  final String internetPing;

  NetworkData({
    required this.wifiName,
    required this.deviceIP,
    required this.gateway,
    required this.publicIP,
    required this.linkSpeed,
    required this.signalStrength,
    required this.freequency,
    required this.rssi,
    required this.gatewayPing,
    required this.internetPing,
  });

  factory NetworkData.fromMap(Map<String, dynamic> map) {
    return NetworkData(
      wifiName: map['wifiName'] ?? '',
      deviceIP: map['deviceIP'] ?? '',
      gateway: map['gateway'] ?? '',
      publicIP: map['publicIP'] ?? '',
      linkSpeed: map['linkSpeed'] ?? '',
      signalStrength: map['signalStrength'] ?? '',
      freequency: map['freequency'] ?? '',
      rssi: map['rssi'] ?? '',
      gatewayPing: map['gatewayPing'] ?? '',
      internetPing: map['internetPing'] ?? '',
    );
  }

  // Convert the NetworkData to a Map for JSON conversion
  Map<String, dynamic> toJson() {
    return {
      'wifiName': wifiName.replaceAll('""', '').replaceAll(r'"', ''),
      'deviceIP': deviceIP,
      'gateway': gateway,
      'publicIP': publicIP,
      'linkSpeed': linkSpeed,
      'signalStrength': signalStrength,
      'freequency': freequency,
      'rssi': rssi,
      'gatewayPing': gatewayPing,
      'internetPing': internetPing,
    };
  }

  @override
  String toString() {
    return 'NetworkData(wifiName: $wifiName, deviceIP: $deviceIP, gateway: $gateway, publicIP: $publicIP, linkSpeed: $linkSpeed, signalStrength: $signalStrength, freequency: $freequency, rssi: $rssi, gatewayPing: $gatewayPing, internetPing: $internetPing)';
  }
}
