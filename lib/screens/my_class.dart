import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udoy_net/models/network_data.dart';

class MyClass {
  get developer => null;


  Future<NetworkData> getNetworkData() async{

    final NetworkInfo _networkInfo = NetworkInfo();

    String wifiName='', wifiIPv4='', wifiGatewayIP='';

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        if (await Permission.locationWhenInUse.request().isGranted) {
    wifiName = await _networkInfo.getWifiName()??'';
    } else {
    wifiName = 'Unauthorized to get Wifi Name';
    }
    } else {
    wifiName = await _networkInfo.getWifiName()??'';
    }
    } on PlatformException catch (e) {
    developer.log('Failed to get Wifi Name', error: e);
    wifiName = 'Failed to get Wifi Name';
    }

    try {
    wifiIPv4 = await _networkInfo.getWifiIP()??'';
    } on PlatformException catch (e) {
    developer.log('Failed to get Wifi IPv4', error: e);
    wifiIPv4 = 'Failed to get Wifi IPv4';
    }

    try {
    wifiGatewayIP = await _networkInfo.getWifiGatewayIP()??'';
    } on PlatformException catch (e) {
    developer.log('Failed to get Wifi gateway address', error: e);
    wifiGatewayIP = 'Failed to get Wifi gateway address';
    }




    return NetworkData(wifiName: wifiName, deviceIP: wifiIPv4, gateway: wifiGatewayIP, publicIP: '', linkSpeed: ''
    , signalStrength: '', freequency: '', rssi: ''  );
  }


}
