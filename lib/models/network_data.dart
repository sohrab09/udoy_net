
class NetworkData {
  final String wifiName;
  final String deviceIP;
  final String gateway;
  final String publicIP;
  final String linkSpeed;
  final String signalStrength;
  final String freequency;
  final String rssi;
  NetworkData({required this.wifiName, required this.deviceIP,
    required this.gateway,required this.publicIP,required this.linkSpeed,
    required this.signalStrength,required this.freequency,required this.rssi,});

  @override
  String toString() {
    return 'NetworkData(Wifi Name: $wifiName, Device IP: $deviceIP, Gateway: $gateway, Public IP: $publicIP, Link Speed: $linkSpeed, Signal Strength: $signalStrength, Frequency: $freequency, RSSI: $rssi)';
  }
}
