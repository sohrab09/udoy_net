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
  final List<Map<String, dynamic>>? availableNetworks;

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
    this.availableNetworks,
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
      availableNetworks: map['availableNetworks'] != null
          ? List<Map<String, dynamic>>.from(map['availableNetworks'])
          : null, // Handle the new variable
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
      'availableNetworks': availableNetworks,
    };
  }

  @override
  String toString() {
    return 'NetworkData(wifiName: $wifiName, deviceIP: $deviceIP, gateway: $gateway, publicIP: $publicIP, linkSpeed: $linkSpeed, signalStrength: $signalStrength, freequency: $freequency, rssi: $rssi, gatewayPing: $gatewayPing, internetPing: $internetPing, availableNetworks: $availableNetworks)';
  }
}
