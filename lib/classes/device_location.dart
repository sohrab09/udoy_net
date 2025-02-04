import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class DeviceLocation {
  final Location location = Location();

  Future<void> forceOpenDeviceLocation(BuildContext context) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        // If the service is not enabled, open the location settings
        await launchUrl(Uri.parse('app-settings:'));
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // If the permission is denied, open the app settings
        await launchUrl(Uri.parse('app-settings:'));
        return;
      }
    }
  }
}
